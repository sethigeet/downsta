import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:downsta/services/services.dart';
import 'package:downsta/models/models.dart';
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
    List<dynamic> items = reels["items"];

    if (items.isEmpty) {
      return const NoContent(
        message: "This user has no reels!",
        icon: Icons.list_rounded,
      );
    }

    var pagingInfo = reels["paging_info"];
    var moreAvailable = pagingInfo["more_available"];
    if (moreAvailable) {
      endCursor = pagingInfo["max_id"];
    } else {
      endCursor = null;
    }

    return Stack(
      children: [
        GridView.builder(
            itemCount: moreAvailable ? items.length + 1 : items.length,
            controller: _scrollController,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 9 / 16,
            ),
            itemBuilder: (context, index) {
              if (moreAvailable && index == items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final reel = items[index]["media"];
              final imageUrl =
                  reel["image_versions2"]["candidates"].last["url"];
              final toBeDownloaded = toDownload.contains(index);
              return Hero(
                tag: "reel-${reel["id"]}",
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
                        ReelScreen.routeName,
                        arguments: ReelScreenArguments(
                            reel: reel, username: reel["user"]["username"]),
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
                      CachedImage(imageUrl: imageUrl),
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
                        List<HistoryItem> histItems = [];
                        List<String> urls = [];
                        for (var idx in toDownload) {
                          final reel = items[idx]["media"];
                          final videoUrl = reel["video_versions"].first["url"];
                          urls.add(videoUrl);
                          histItems.add(HistoryItem.create(
                            postId: reel["id"],
                            coverImgUrl: reel["image_versions2"]["candidates"]
                                .last["url"],
                            imageUrls: videoUrl,
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
