import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import 'package:drift/drift.dart' show Value;

import 'package:downsta/services/services.dart';
import 'package:downsta/widgets/widgets.dart';
import 'package:downsta/screens/screens.dart';

class Posts extends StatefulWidget {
  const Posts({Key? key, required this.username}) : super(key: key);

  final String username;

  @override
  State<Posts> createState() => _PostsState();
}

class _PostsState extends State<Posts> {
  final _scrollController = ScrollController();
  final _keyboardScrollFocusNode = FocusNode();
  String? nextMaxId;
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
    _scrollController.dispose();
    _keyboardScrollFocusNode.dispose();

    super.dispose();
  }

  void _scrollListener() async {
    if (nextMaxId == null) {
      return;
    }

    // if (_scrollController.position.extentAfter <= 100) {
    if (_scrollController.position.extentAfter == 0) {
      final api = Provider.of<Api>(context, listen: false);

      await api.getPosts(widget.username, nextMaxId: nextMaxId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final downloader = Provider.of<Downloader>(context, listen: false);
    final db = Provider.of<DB>(context, listen: false);
    final api = context.watch<Api>();
    final userInfo = api.cache.profiles[widget.username];
    if (userInfo == null) {
      // it is already being requested by the `parent` so no need to request again!

      return Container();
    }

    var posts = userInfo.posts.items;

    if (posts.isEmpty) {
      return const NoContent(
        message: "This user has no posts!",
        icon: Icons.list_rounded,
      );
    }

    var hasMorePosts = userInfo.posts.moreAvailable;
    nextMaxId = userInfo.posts.nextMaxId;

    return Stack(
      children: [
        KeyboardListener(
          focusNode: _keyboardScrollFocusNode,
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.home) {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                );
                return;
              }

              double delta = 0;
              if (event.character == "j" ||
                  event.logicalKey == LogicalKeyboardKey.arrowDown) {
                delta = 100;
              } else if (event.character == "d" ||
                  event.logicalKey == LogicalKeyboardKey.pageDown) {
                delta = 500;
              } else if (event.character == "k" ||
                  event.logicalKey == LogicalKeyboardKey.arrowUp) {
                delta = -100;
              } else if (event.character == "u" ||
                  event.logicalKey == LogicalKeyboardKey.pageUp) {
                delta = -500;
              }
              _scrollController.animateTo(
                _scrollController.offset + delta,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
              );
            }
          },
          child: Listener(
            onPointerHover: (event) {
              if (!_keyboardScrollFocusNode.hasFocus &&
                  event.kind == PointerDeviceKind.mouse) {
                // Request focus in order to be able to use keyboard keys
                FocusScope.of(context).requestFocus(_keyboardScrollFocusNode);
              }
            },
            child: GridView.builder(
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

                  final post = posts[index];
                  final imageUrl = post.displayUrl;
                  final toBeDownloaded = toDownload.contains(index);
                  return FutureBuilder<bool>(
                      future: db.isPostDownloaded(post.id),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final bool alreadyDownloaded = snap.data!;
                        return Hero(
                          tag: "post-${post.id}",
                          child: GestureDetector(
                            onTap: () {
                              if (selectionStarted) {
                                if (!alreadyDownloaded) {
                                  setState(() {
                                    if (toBeDownloaded) {
                                      toDownload.remove(index);
                                    } else {
                                      toDownload.add(index);
                                    }
                                  });
                                }
                              } else {
                                Navigator.pushNamed(
                                  context,
                                  PostScreen.routeName,
                                  arguments: PostScreenArguments(
                                    post: post,
                                    index: index,
                                    username: widget.username,
                                  ),
                                );
                              }
                            },
                            onLongPress: () {
                              if (selectionStarted) {
                                if (!alreadyDownloaded) {
                                  setState(() {
                                    if (toBeDownloaded) {
                                      toDownload.remove(index);
                                    } else {
                                      toDownload.add(index);
                                    }
                                  });
                                }
                              } else {
                                setState(() {
                                  selectionStarted = true;
                                  if (!alreadyDownloaded) {
                                    toDownload.add(index);
                                  }
                                });
                              }
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedImage(imageUrl: imageUrl),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: DownloadedStatus(
                                    show: selectionStarted,
                                    toBeDownloaded: toBeDownloaded,
                                    alreadyDownloaded: alreadyDownloaded,
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      });
                }),
          ),
        ),
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
                    onPressed: () async {
                      if (selectionStarted) {
                        List<HistoryItemsCompanion> histItems = [];
                        List<String> urls = [];
                        for (var idx in toDownload) {
                          final post = posts[idx];
                          final images = post.urls;
                          urls.addAll(images);
                          histItems.add(HistoryItemsCompanion.insert(
                            postId: post.id,
                            coverImgBytes: Value(
                                await downloader.getImgBytes(post.displayUrl)),
                            imgUrls: images.join(","),
                            username: widget.username,
                          ));
                        }
                        db.saveItemsToHistory(histItems);
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
