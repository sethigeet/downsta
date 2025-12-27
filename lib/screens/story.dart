import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:drift/drift.dart' show Value;
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import 'package:downsta/globals.dart';
import 'package:downsta/services/services.dart';
import 'package:downsta/models/models.dart';
import 'package:downsta/widgets/widgets.dart';

class StoryScreenArguments {
  Story story;
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
  final _photoController = PhotoViewController();
  final _keyboardScrollFocusNode = FocusNode();

  int activeIndex = 0;
  bool showOverlays = true;
  double _currentOpacity = 1;
  bool _isCtrlPressed = false;

  @override
  void dispose() {
    // reset the display state
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);

    _videoController?.dispose();
    _chewieController?.dispose();

    _photoController.dispose();
    _keyboardScrollFocusNode.dispose();

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
    final isVideo = story.isVideo;

    String storyUrl = story.urls.first;
    String coverImgUrl = story.displayUrl;
    final alreadyDownloaded = db.isDownloadedCache[story.id] ?? false;

    if (isVideo && kIsMobile) {
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
                  splashColor:
                      theme.colorScheme.onPrimary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(25),
                  onLongPress: () async {
                    final toDownload = await showModalBottomSheet<List<String>>(
                        context: context,
                        builder: (context) {
                          return SizedBox(
                            height: isVideo ? 150 : 50,
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
                                    leading: const Icon(Icons.image)),
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
                          postId: story.id,
                          coverImgBytes:
                              Value(await downloader.getImgBytes(coverImgUrl)),
                          imgUrls: storyUrl,
                          username: args.username,
                        ));
                      }
                      downloader.download(toDownload, args.username);
                    }
                  },
                  onTap: alreadyDownloaded
                      ? null
                      : () async {
                          downloader.download([storyUrl], args.username);
                          db.saveItemToHistory(HistoryItemsCompanion.insert(
                            postId: story.id,
                            coverImgBytes: Value(
                                await downloader.getImgBytes(coverImgUrl)),
                            imgUrls: storyUrl,
                            username: args.username,
                          ));
                        },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      alreadyDownloaded
                          ? Icons.download_done_rounded
                          : Icons.download,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
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
        child: KeyboardListener(
          focusNode: _keyboardScrollFocusNode,
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              setState(() => _isCtrlPressed =
                  event.logicalKey == LogicalKeyboardKey.controlLeft);
            } else if (event is KeyUpEvent) {
              setState(() => _isCtrlPressed =
                  event.logicalKey != LogicalKeyboardKey.controlLeft);
            }
          },
          child: Listener(
            onPointerSignal: (event) {
              // Zoom in and out
              if (_isCtrlPressed) {
                if (event is PointerScrollEvent &&
                    event.kind == PointerDeviceKind.mouse) {
                  // for some reason, the delta is the opposite of what is obvious
                  final double delta = (event.scrollDelta.dy * -1) / 1000;
                  double newScale =
                      max(0, min((_photoController.scale ?? 1) + delta, 4));
                  _photoController.setScaleInvisibly(newScale);
                }

                return;
              }
            },
            onPointerHover: (event) {
              if (!_keyboardScrollFocusNode.hasFocus &&
                  event.kind == PointerDeviceKind.mouse) {
                // Request focus in order to be able to use keyboard keys
                FocusScope.of(context).requestFocus(_keyboardScrollFocusNode);
              }
            },
            child: PhotoView.customChild(
              controller: _photoController,
              heroAttributes: PhotoViewHeroAttributes(tag: "story-${story.id}"),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 4,
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
