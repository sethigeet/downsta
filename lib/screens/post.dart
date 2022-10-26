import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'package:drift/drift.dart' show Value;
import 'package:chewie/chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'package:downsta/globals.dart';
import 'package:downsta/models/models.dart';
import 'package:downsta/services/services.dart';
import 'package:downsta/utils.dart';
import 'package:downsta/widgets/widgets.dart';

class PostScreenArguments {
  Post post;
  int? index;
  String username;

  PostScreenArguments({
    required this.post,
    this.index,
    required this.username,
  });
}

class PostScreen extends StatefulWidget {
  const PostScreen({Key? key}) : super(key: key);
  static const routeName = "/post";

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> with TickerProviderStateMixin {
  final _keyboardScrollFocusNode = FocusNode();
  final _animationDuration = const Duration(milliseconds: 300);

  final _pageController = PageController();
  final _photoController = PhotoViewController();

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  int activeIndex = 0;
  bool showOverlays = true;
  double _currentOpacity = 1;
  bool _isCtrlPressed = false;

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();

    _keyboardScrollFocusNode.dispose();
    _pageController.dispose();
    _photoController.dispose();

    // reset the display state
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);

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
    final api = context.watch<Api>();

    final args =
        ModalRoute.of(context)!.settings.arguments as PostScreenArguments;
    final post = args.post;
    final username = args.username;
    final userInfo = api.cache.profiles[username];
    final index = args.index;

    final images = post.urls;
    final coverImages = post.displayUrls;
    final alreadyDownloaded = db.isDownloadedCache[post.id] ?? false;

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
                  onLongPress: () async {
                    final currUrl = images[(_pageController.page ?? 0).floor()];
                    final toDownload = await showModalBottomSheet<List<String>>(
                        context: context,
                        builder: (context) {
                          return SizedBox(
                            height: 100,
                            child: Column(children: [
                              ListTile(
                                onTap: () => Navigator.pop(context, [currUrl]),
                                title: currUrl.contains(".mp4")
                                    ? const Text("Download current video")
                                    : const Text("Download current image"),
                                leading: const Icon(Icons.image),
                              ),
                              ListTile(
                                  onTap: () => Navigator.pop(context, images),
                                  title: const Text("Download entire post"),
                                  leading: const Icon(Icons.collections)),
                            ]),
                          );
                        });

                    if (toDownload != null) {
                      if (toDownload.length > 1) {
                        db.saveItemToHistory(HistoryItemsCompanion.insert(
                          postId: post.id,
                          coverImgBytes: Value(
                              await downloader.getImgBytes(post.displayUrl)),
                          imgUrls: images.join(","),
                          username: username,
                        ));
                      }
                      downloader.download(toDownload, username);
                    }
                  },
                  onTap: alreadyDownloaded
                      ? null
                      : () async {
                          downloader.download(images, username);
                          db.saveItemToHistory(HistoryItemsCompanion.insert(
                            postId: post.id,
                            coverImgBytes: Value(
                                await downloader.getImgBytes(post.displayUrl)),
                            imgUrls: images.join(","),
                            username: username,
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
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            KeyboardListener(
              focusNode: _keyboardScrollFocusNode,
              onKeyEvent: (event) {
                if (index != null) {
                  if (event.character == "n") {
                    var posts = userInfo!.posts.edges;
                    if (index == posts.length - 1) {
                      return;
                    }

                    Navigator.pushReplacementNamed(
                      context,
                      PostScreen.routeName,
                      arguments: PostScreenArguments(
                        post: posts[index + 1],
                        index: index + 1,
                        username: username,
                      ),
                    );

                    return;
                  } else if (event.character == "p") {
                    var posts = userInfo!.posts.edges;
                    if (index == 0) {
                      return;
                    }

                    Navigator.pushReplacementNamed(
                      context,
                      PostScreen.routeName,
                      arguments: PostScreenArguments(
                        post: posts[index - 1],
                        index: index - 1,
                        username: username,
                      ),
                    );

                    return;
                  }
                }

                if (event.character == "q" ||
                    event.logicalKey == LogicalKeyboardKey.backspace) {
                  Navigator.pop(context);
                  return;
                }

                int delta = 0;
                if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                  delta = 1;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  delta = -1;
                }

                _pageController.animateToPage(
                  activeIndex + delta,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );

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

                  // Move between the images with the mouse
                  if (event is PointerScrollEvent &&
                      event.kind == PointerDeviceKind.mouse) {
                    int delta;
                    if (event.scrollDelta.dx > 0 || event.scrollDelta.dy > 0) {
                      delta = 1;
                    } else {
                      delta = -1;
                    }

                    _pageController.animateToPage(
                      activeIndex + delta,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
                onPointerHover: (event) {
                  if (!_keyboardScrollFocusNode.hasFocus &&
                      event.kind == PointerDeviceKind.mouse) {
                    // Request focus in order to be able to use keyboard keys
                    FocusScope.of(context)
                        .requestFocus(_keyboardScrollFocusNode);
                  }
                },
                child: PhotoViewGallery.builder(
                  itemCount: images.length,
                  scrollPhysics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  pageController: _pageController,
                  onPageChanged: (index) => setState(() {
                    activeIndex = index;
                  }),
                  backgroundDecoration:
                      BoxDecoration(color: theme.backgroundColor),
                  builder: (context, index) {
                    final url = images[index];
                    final coverImgUrl = coverImages[index];
                    if (url.contains(".mp4")) {
                      if (kIsMobile) {
                        initializePlayer(url, coverImgUrl);
                      }
                      return PhotoViewGalleryPageOptions.customChild(
                        child: _chewieController == null
                            ? buildLoadingWidget(coverImgUrl)
                            : !_chewieController!
                                    .videoPlayerController.value.isInitialized
                                ? buildLoadingWidget(coverImgUrl)
                                : Chewie(controller: _chewieController!),
                        controller: _photoController,
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 4,
                        heroAttributes:
                            PhotoViewHeroAttributes(tag: "post-${post.id}"),
                      );
                    }

                    return PhotoViewGalleryPageOptions(
                      controller: _photoController,
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 4,
                      imageProvider: CachedNetworkImageProvider(url,
                          cacheKey: getCacheKey(url)),
                      initialScale: PhotoViewComputedScale.contained,
                      errorBuilder: (context, error, _) => const Center(
                        child: SizedBox(
                          width: 25,
                          height: 25,
                          child: Icon(Icons.error),
                        ),
                      ),
                      heroAttributes:
                          PhotoViewHeroAttributes(tag: "post-${post.id}"),
                    );
                  },
                  loadingBuilder: (context, event) => Center(
                    child: SizedBox(
                        width: 25,
                        height: 25,
                        child: CircularProgressIndicator(
                          value: (event == null ||
                                  event.expectedTotalBytes == null)
                              ? null
                              : event.cumulativeBytesLoaded /
                                  event
                                      .expectedTotalBytes!, // why does dart think that I am not checking expectedTotalBytes to be null 2 lines above??)),
                        )),
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _currentOpacity,
              duration: _animationDuration,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: buildIndicators(images.length),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildIndicators(imagesLength) {
    return SmoothPageIndicator(
      controller: _pageController,
      count: imagesLength,
      effect: ScrollingDotsEffect(
        dotWidth: 10,
        dotHeight: 10,
        dotColor: Colors.grey.shade800,
        activeDotColor: Colors.deepPurple.shade900,
      ),
      onDotClicked: (index) => _pageController.animateToPage(
        index,
        duration: _animationDuration,
        curve: Curves.easeInOut,
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
