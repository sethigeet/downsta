import 'dart:math';

import 'package:flutter/material.dart';

import 'package:drift/drift.dart' show Value;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import 'package:downsta/globals.dart';
import 'package:downsta/models/models.dart';
import 'package:downsta/services/services.dart';
import 'package:downsta/utils.dart';
import 'package:downsta/widgets/widgets.dart';
import 'package:downsta/screens/screens.dart';

class PostCard extends StatefulWidget {
  const PostCard({
    Key? key,
    required this.post,
  }) : super(key: key);

  final Post post;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final _pageController = PageController();
  final _photoController = PhotoViewController();

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  int activeIndex = 0;
  bool showOverlays = true;

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();

    _pageController.dispose();
    _photoController.dispose();

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
    final size = MediaQuery.of(context).size;

    final db = Provider.of<DB>(context);
    final downloader = Provider.of<Downloader>(context);

    final username = widget.post.username;

    final urls = widget.post.urls;
    final coverImgUrls = widget.post.displayUrls;

    return FutureBuilder<bool>(
        future: db.isPostDownloaded(widget.post.id),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bool alreadyDownloaded = snap.data!;
          return Card(
            child: Column(children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  ProfileScreen.routeName,
                  arguments: ProfileScreenArguments(username: username),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: CachedNetworkImageProvider(
                          widget.post.profilePicUrl,
                          cacheKey: getCacheKey(widget.post.profilePicUrl),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        username,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: alreadyDownloaded
                            ? null
                            : () async {
                                final urls = widget.post.urls;
                                downloader.download(urls, username);
                                db.saveItemToHistory(
                                    HistoryItemsCompanion.insert(
                                  postId: widget.post.id,
                                  coverImgBytes: Value(await downloader
                                      .getImgBytes(widget.post.displayUrl)),
                                  imgUrls: urls.join(","),
                                  username: username,
                                ));
                              },
                        icon: alreadyDownloaded
                            ? const Icon(Icons.download_done_rounded)
                            : const Icon(Icons.download_rounded),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, PostScreen.routeName,
                                arguments: PostScreenArguments(
                                  post: widget.post,
                                  username: username,
                                )),
                        icon: const Icon(Icons.open_in_full_rounded),
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: min(
                  widget.post.aspectRatio * size.width,
                  widget.post.height.toDouble(),
                ),
                child: Stack(
                  children: [
                    PhotoViewGallery.builder(
                      itemCount: urls.length,
                      scrollPhysics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics()),
                      pageController: _pageController,
                      onPageChanged: (index) =>
                          setState(() => activeIndex = index),
                      backgroundDecoration:
                          BoxDecoration(color: theme.colorScheme.background),
                      builder: (context, index) {
                        final url = urls[index];
                        final coverImgUrl = coverImgUrls[index];
                        if (url.contains(".mp4")) {
                          if (kIsMobile) {
                            initializePlayer(url, coverImgUrl);
                          }
                          return PhotoViewGalleryPageOptions.customChild(
                            child: _chewieController == null
                                ? buildLoadingWidget(coverImgUrl)
                                : !_chewieController!.videoPlayerController
                                        .value.isInitialized
                                    ? buildLoadingWidget(coverImgUrl)
                                    : Chewie(controller: _chewieController!),
                            controller: _photoController,
                            minScale: PhotoViewComputedScale.contained,
                            maxScale: PhotoViewComputedScale.covered * 4,
                            heroAttributes: PhotoViewHeroAttributes(
                                tag: "post-${widget.post.id}"),
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
                          heroAttributes: PhotoViewHeroAttributes(
                              tag: "post-${widget.post.id}"),
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
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: buildIndicators(urls.length),
                      ),
                    )
                  ],
                ),
              ),
            ]),
          );
        });
  }

  Widget buildIndicators(imagesLength) {
    if (imagesLength == 1) {
      return Container();
    }

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
        duration: const Duration(milliseconds: 300),
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
