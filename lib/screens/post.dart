import 'dart:math';

import 'package:downsta/models/history_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:provider/provider.dart';

import 'package:downsta/services/services.dart';
import 'package:downsta/utils.dart';

class PostsScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

class PostScreenArguments {
  dynamic post;
  String username;

  PostScreenArguments({
    required this.post,
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

  int activeIndex = 0;
  bool showOverlays = true;
  double _currentOpacity = 1;
  bool _isCtrlPressed = false;

  @override
  void dispose() {
    _keyboardScrollFocusNode.dispose();

    // reset the display state
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final db = Provider.of<DB>(context, listen: false);
    final downloader = Provider.of<Downloader>(context, listen: false);

    final args =
        ModalRoute.of(context)!.settings.arguments as PostScreenArguments;
    final post = args.post;
    final username = args.username;

    List<String> images = [];
    if (post["edge_sidecar_to_children"] != null) {
      images.addAll(List<String>.from(post["edge_sidecar_to_children"]["edges"]
          .map((post) => post["node"]["display_url"])));
    } else {
      images.add(post["display_url"]);
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
                                onTap: () => Navigator.pop(context, [
                                  images[(_pageController.page ?? 0).floor()]
                                ]),
                                title: const Text("Download current image"),
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
                        db.saveItemToHistory(HistoryItem.create(
                          postId: post["id"],
                          coverImgUrl: post["display_url"],
                          imageUrls: images,
                          username: username,
                        ));
                      }
                      downloader.download(toDownload, username);
                    }
                  },
                  onTap: () {
                    downloader.download(images, username);
                    db.saveItemToHistory(HistoryItem.create(
                      postId: post["id"],
                      coverImgUrl: post["display_url"],
                      imageUrls: images,
                      username: username,
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
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            KeyboardListener(
              focusNode: _keyboardScrollFocusNode,
              onKeyEvent: (event) {
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
                  builder: (context, index) => PhotoViewGalleryPageOptions(
                    controller: _photoController,
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 4,
                    imageProvider: CachedNetworkImageProvider(
                      images[index],
                      cacheKey: getCacheKey(images[index]),
                    ),
                    initialScale: PhotoViewComputedScale.contained,
                    errorBuilder: (context, error, _) => const Center(
                      child: SizedBox(
                        width: 25,
                        height: 25,
                        child: Icon(Icons.error),
                      ),
                    ),
                    heroAttributes:
                        PhotoViewHeroAttributes(tag: "post-${post["id"]}"),
                  ),
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
}
