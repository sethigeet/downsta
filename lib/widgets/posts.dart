import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import 'package:downsta/services/downloader.dart';
import 'package:downsta/services/api.dart';
import 'package:downsta/utils.dart';
import 'package:downsta/screens/post.dart';

class Posts extends StatefulWidget {
  const Posts({Key? key, required this.username}) : super(key: key);

  final String username;

  @override
  State<Posts> createState() => _PostsState();
}

class _PostsState extends State<Posts> {
  final _scrollController = ScrollController();
  String? endCursor;
  bool selectionStarted = false;
  Set<int> toDownload = {};

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);

    super.dispose();
  }

  void _scrollListener() async {
    if (endCursor == null) {
      return;
    }

    // if (_scrollController.position.extentAfter <= 100) {
    if (_scrollController.position.extentAfter == 0) {
      final api = Provider.of<Api>(context, listen: false);
      await api.getMorePosts(widget.username, endCursor!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final downloader = Provider.of<Downloader>(context, listen: false);
    final api = context.watch<Api>();
    final userInfo = api.userInfo[widget.username];
    if (userInfo == null) {
      // it is already being requested by the `parent` so no need to request again!

      return Container();
    }
    var posts = userInfo["edge_owner_to_timeline_media"]["edges"];

    var pageInfo = userInfo["edge_owner_to_timeline_media"]["page_info"];
    var hasMorePosts = pageInfo["has_next_page"];
    if (hasMorePosts) {
      endCursor = pageInfo["end_cursor"];
    } else {
      endCursor = null;
    }

    return Stack(
      children: [
        GridView.builder(
            itemCount: hasMorePosts ? posts.length + 1 : posts.length,
            controller: _scrollController,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              if (hasMorePosts && index == posts.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final post = posts[index]["node"];
              final imageUrl = post["display_url"];
              final toBeDownloaded = toDownload.contains(index);
              return Hero(
                tag: "post-${post["id"]}",
                child: GestureDetector(
                  onTap: () {
                    if (selectionStarted) {
                      setState(() {
                        if (toBeDownloaded) {
                          toDownload.remove(index);
                        } else {
                          toDownload.add(index);
                        }
                      });
                    } else {
                      Navigator.pushNamed(
                        context,
                        "/post",
                        arguments: PostScreenArguments(
                            post: post, username: post["owner"]["username"]),
                      );
                    }
                  },
                  onLongPress: () {
                    if (selectionStarted) {
                      setState(() {
                        if (toBeDownloaded) {
                          toDownload.remove(index);
                        } else {
                          toDownload.add(index);
                        }
                      });
                    } else {
                      setState(() {
                        selectionStarted = true;
                        toDownload.add(index);
                      });
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        cacheKey: getCacheKey(imageUrl),
                        fit: BoxFit.cover,
                        progressIndicatorBuilder:
                            (context, url, downloadProgress) => Container(
                          color: theme.backgroundColor,
                          child: Center(
                              child: CircularProgressIndicator(
                                  value: downloadProgress.progress)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.backgroundColor,
                          child: const Center(child: Icon(Icons.error)),
                        ),
                      ),
                      Positioned(
                          top: 10,
                          right: 10,
                          child: selectionStarted
                              ? (toBeDownloaded
                                  ? Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(25),
                                        color: theme.colorScheme.primary,
                                      ),
                                      height: 25,
                                      width: 25,
                                      child: Icon(
                                        Icons.check,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                          border: Border.all(
                                            color: theme.colorScheme.primary,
                                            width: 2,
                                          )),
                                      height: 25,
                                      width: 25,
                                    ))
                              : Container())
                    ],
                  ),
                ),
              );
            }),
        Positioned(
          right: 15,
          bottom: 15,
          child: Column(
            children: [
              if (selectionStarted)
                Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: theme.colorScheme.secondary,
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          selectionStarted = false;
                          toDownload.clear();
                        });
                      },
                      icon: Icon(
                        Icons.cancel_outlined,
                        color: theme.colorScheme.onSecondary,
                      ),
                    ))
              else
                Container(),
              const SizedBox(height: 15),
              Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: theme.colorScheme.primary,
                  ),
                  child: IconButton(
                    onPressed: () {
                      if (selectionStarted) {
                        List<String> urls = [];
                        for (var idx in toDownload) {
                          final post = posts[idx]["node"];
                          List<String> images = [];
                          if (post["edge_sidecar_to_children"] != null) {
                            images.addAll(List<String>.from(
                                post["edge_sidecar_to_children"]["edges"].map(
                                    (post) => post["node"]["display_url"])));
                          } else {
                            images.add(post["display_url"]);
                          }

                          urls.addAll(images);
                        }
                        downloader.download(
                          urls,
                          widget.username,
                        );
                        setState(() {
                          selectionStarted = false;
                          toDownload.clear();
                        });
                      } else {
                        setState(() => selectionStarted = true);
                      }
                    },
                    icon: Icon(
                      Icons.download,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )),
            ],
          ),
        )
      ],
    );
  }
}
