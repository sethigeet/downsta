import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:drift/drift.dart' show Value;
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import 'package:downsta/services/services.dart';
import 'package:downsta/widgets/widgets.dart';

class StoryScreenArguments {
  dynamic story;
  String username;

  StoryScreenArguments({
    required this.story,
    required this.username,
  });
}

class StoryScreen extends StatefulWidget {
  const StoryScreen({Key? key}) : super(key: key);
  static const routeName = "/story";

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen>
    with TickerProviderStateMixin {
  final _animationDuration = const Duration(milliseconds: 300);
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  int activeIndex = 0;
  bool showOverlays = true;
  double _currentOpacity = 1;

  @override
  void dispose() {
    // reset the display state
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);

    _videoController?.dispose();
    _chewieController?.dispose();

    super.dispose();
  }

  void initializePlayer(String url, String coverImgUrl) async {
    _videoController = VideoPlayerController.network(url);
    await _videoController!.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      errorBuilder: (context, msg) => ErrorDisplay(message: msg),
      placeholder: CachedImage(imageUrl: coverImgUrl),
      autoPlay: true,
      looping: false,
      allowMuting: true,
      zoomAndPan: true,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final db = Provider.of<DB>(context, listen: false);
    final downloader = Provider.of<Downloader>(context, listen: false);

    final args =
        ModalRoute.of(context)!.settings.arguments as StoryScreenArguments;
    final story = args.story;
    final isVideo = story["is_video"];

    String coverImgUrl = story["display_url"];

    String storyUrl = isVideo
        ? story["video_resources"].first["src"]
        : story["display_resources"].last["src"];

    if (isVideo) {
      initializePlayer(storyUrl, coverImgUrl);
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size(MediaQuery.of(context).size.width, 56),
        child: AnimatedOpacity(
          opacity: _currentOpacity,
          duration: _animationDuration,
          child: AppBar(),
        ),
      ),
      extendBodyBehindAppBar: true,
      floatingActionButton: _currentOpacity == 1
          ? Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(25),
              ),
              margin: const EdgeInsets.symmetric(vertical: 25),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  splashColor: theme.colorScheme.onPrimary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.download,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  onLongPress: () async {
                    final toDownload = await showModalBottomSheet<List<String>>(
                        context: context,
                        builder: (context) {
                          return SizedBox(
                            height: 100,
                            child: Column(children: [
                              ListTile(
                                onTap: () => Navigator.pop(context, [storyUrl]),
                                title: const Text("Download story"),
                                leading: const Icon(Icons.image),
                              ),
                              if (isVideo)
                                ListTile(
                                    onTap: () =>
                                        Navigator.pop(context, [coverImgUrl]),
                                    title: const Text("Download cover image"),
                                    leading: const Icon(Icons.collections)),
                              if (isVideo)
                                ListTile(
                                    onTap: () => Navigator.pop(
                                        context, [coverImgUrl, storyUrl]),
                                    title: const Text("Download both"),
                                    leading: const Icon(Icons.collections)),
                            ]),
                          );
                        });

                    if (toDownload != null) {
                      if (toDownload.contains(storyUrl)) {
                        db.saveItemToHistory(HistoryItemsCompanion.insert(
                          postId: story["id"],
                          coverImgBytes:
                              Value(await downloader.getImgBytes(coverImgUrl)),
                          imgUrls: storyUrl,
                          username: args.username,
                        ));
                      }
                      downloader.download(toDownload, args.username);
                    }
                  },
                  onTap: () async {
                    downloader.download([storyUrl], args.username);
                    db.saveItemToHistory(HistoryItemsCompanion.insert(
                      postId: story["id"],
                      coverImgBytes:
                          Value(await downloader.getImgBytes(coverImgUrl)),
                      imgUrls: storyUrl,
                      username: args.username,
                    ));
                  },
                ),
              ),
            )
          : null,
      body: GestureDetector(
        onTap: () {
          if (_currentOpacity > 0) {
            setState(() => _currentOpacity = 0);
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
          } else {
            setState(() => _currentOpacity = 1);
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
                overlays: SystemUiOverlay.values);
          }
        },
        child: Column(
          children: [
            Expanded(
              child: Hero(
                tag: "story-${story["id"]}",
                child: Center(
                  child: isVideo
                      ? _chewieController == null
                          ? buildLoadingWidget(coverImgUrl)
                          : !_chewieController!
                                  .videoPlayerController.value.isInitialized
                              ? buildLoadingWidget(coverImgUrl)
                              : Chewie(controller: _chewieController!)
                      : CachedImage(imageUrl: storyUrl),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLoadingWidget(String coverImgUrl) {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        CachedImage(imageUrl: coverImgUrl),
        const CircularProgressIndicator(),
      ],
    );
  }
}
