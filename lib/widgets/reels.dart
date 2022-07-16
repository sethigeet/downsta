import 'package:flutter/material.dart';

import 'package:drift/drift.dart' show Value;
import 'package:provider/provider.dart';

import 'package:downsta/services/services.dart';
import 'package:downsta/widgets/widgets.dart';
import 'package:downsta/screens/screens.dart';

class Reels extends StatefulWidget {
  const Reels({Key? key, required this.username}) : super(key: key);

  final String username;

  @override
  State<Reels> createState() => _ReelsState();
}

class _ReelsState extends State<Reels> {
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
    _scrollController.dispose();

    super.dispose();
  }

  void _scrollListener() async {
    if (endCursor == null) {
      return;
    }

    // if (_scrollController.position.extentAfter <= 100) {
    if (_scrollController.position.extentAfter == 0) {
      final api = Provider.of<Api>(context, listen: false);

      await api.getReels(
        widget.username,
        endCursor: endCursor!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final downloader = Provider.of<Downloader>(context, listen: false);
    final db = Provider.of<DB>(context, listen: false);
    final api = context.watch<Api>();
    final reels = api.cache.reels[widget.username];
    if (reels == null) {
      api.getReels(widget.username);
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    final items = reels.edges;

    if (items.isEmpty) {
      return const NoContent(
        message: "This user has no reels!",
        icon: Icons.list_rounded,
      );
    }

    var hasMoreReels = reels.hasMoreEdges;
    endCursor = reels.endCursor;

    return Stack(
      children: [
        GridView.builder(
            itemCount: hasMoreReels ? items.length + 1 : items.length,
            controller: _scrollController,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 9 / 16,
            ),
            itemBuilder: (context, index) {
              if (hasMoreReels && index == items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final reel = items[index];
              final imageUrl = reel.displayUrl;
              final toBeDownloaded = toDownload.contains(index);
              return FutureBuilder<bool>(
                  future: db.isPostDownloaded(reel.id),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final bool alreadyDownloaded = snap.data!;
                    return Hero(
                      tag: "reel-${reel.id}",
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
                              ReelScreen.routeName,
                              arguments: ReelScreenArguments(
                                reel: reel,
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
                                child: selectionStarted
                                    ? DownloadedStatus(
                                        show: selectionStarted,
                                        toBeDownloaded: toBeDownloaded,
                                        alreadyDownloaded: alreadyDownloaded,
                                      )
                                    : Container())
                          ],
                        ),
                      ),
                    );
                  });
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
                    onPressed: () async {
                      if (selectionStarted) {
                        List<HistoryItemsCompanion> histItems = [];
                        List<String> urls = [];
                        for (var idx in toDownload) {
                          final reel = items[idx];
                          final videoUrl = reel.urls.first;
                          urls.add(videoUrl);
                          histItems.add(HistoryItemsCompanion.insert(
                            postId: reel.id,
                            coverImgBytes: Value(
                                await downloader.getImgBytes(reel.displayUrl)),
                            imgUrls: videoUrl,
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
