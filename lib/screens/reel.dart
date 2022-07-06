import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:drift/drift.dart' show Value;
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import 'package:downsta/services/services.dart';

class ReelScreenArguments {
  dynamic reel;
  String username;

  ReelScreenArguments({
    required this.reel,
    required this.username,
  });
}

class ReelScreen extends StatefulWidget {
  const ReelScreen({Key? key}) : super(key: key);
  static const routeName = "/reel";

  @override
  State<ReelScreen> createState() => _ReelScreenState();
}

class _ReelScreenState extends State<ReelScreen> with TickerProviderStateMixin {
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

  void initializePlayer(String url) async {
    _videoController = VideoPlayerController.network(url);
    await _videoController!.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
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
        ModalRoute.of(context)!.settings.arguments as ReelScreenArguments;
    final reel = args.reel;
    String imageUrl = reel["image_versions2"]["candidates"].first["url"];
    String videoUrl = reel["video_versions"].first["url"];

    initializePlayer(videoUrl);

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
                                onTap: () => Navigator.pop(context, [videoUrl]),
                                title: const Text("Download video"),
                                leading: const Icon(Icons.image),
                              ),
                              ListTile(
                                  onTap: () =>
                                      Navigator.pop(context, [imageUrl]),
                                  title: const Text("Download cover image"),
                                  leading: const Icon(Icons.collections)),
                              ListTile(
                                  onTap: () => Navigator.pop(
                                      context, [imageUrl, videoUrl]),
                                  title: const Text("Download both"),
                                  leading: const Icon(Icons.collections)),
                            ]),
                          );
                        });

                    if (toDownload != null) {
                      if (toDownload.contains(videoUrl)) {
                        db.saveItemToHistory(HistoryItemsCompanion.insert(
                          postId: reel["id"],
                          coverImgBytes:
                              Value(await downloader.getImgBytes(imageUrl)),
                          imgUrls: videoUrl,
                          username: args.username,
                        ));
                      }
                      downloader.download(toDownload, args.username);
                    }
                  },
                  onTap: () async {
                    downloader.download([videoUrl], args.username);
                    db.saveItemToHistory(HistoryItemsCompanion.insert(
                      postId: reel["id"],
                      coverImgBytes:
                          Value(await downloader.getImgBytes(imageUrl)),
                      imgUrls: videoUrl,
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
                tag: "reel-${reel["id"]}",
                child: Center(
                  child: _chewieController == null
                      ? buildLoadingWidget()
                      : !_chewieController!
                              .videoPlayerController.value.isInitialized
                          ? buildLoadingWidget()
                          : Chewie(controller: _chewieController!),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLoadingWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        CircularProgressIndicator(),
        SizedBox(height: 20),
        Text('Loading'),
      ],
    );
  }
}
