import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:downsta/services/services.dart';
import 'package:downsta/widgets/widgets.dart';
import 'package:downsta/screens/screens.dart';

class Stories extends StatefulWidget {
  const Stories({Key? key, required this.username}) : super(key: key);

  final String username;

  @override
  State<Stories> createState() => _StoriesState();
}

class _StoriesState extends State<Stories> {
  bool selectionStarted = false;
  Set<int> toDownload = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final downloader = Provider.of<Downloader>(context, listen: false);
    final db = Provider.of<DB>(context, listen: false);
    final api = context.watch<Api>();
    final stories = api.cache.stories[widget.username];
    if (stories == null) {
      api.getStories(widget.username);
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    List<dynamic> items = stories.isEmpty ? [] : stories["items"];

    if (items.isEmpty) {
      return const NoContent(
        message: "This user has no stories!",
        icon: Icons.list_rounded,
      );
    }

    return Stack(
      children: [
        GridView.builder(
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 9 / 16,
            ),
            itemBuilder: (context, index) {
              final story = items[index];
              final imageUrl = story["display_url"];
              final toBeDownloaded = toDownload.contains(index);
              return FutureBuilder<bool>(
                  future: db.isPostDownloaded(story["id"]),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final bool alreadyDownloaded = snap.data!;
                    return Hero(
                      tag: "story-${story["id"]}",
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
                              StoryScreen.routeName,
                              arguments: StoryScreenArguments(
                                story: story,
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
                    onPressed: () {
                      if (selectionStarted) {
                        List<HistoryItemsCompanion> histItems = [];
                        List<String> urls = [];
                        for (var idx in toDownload) {
                          final story = items[idx];
                          final isVideo = story["is_video"];
                          String storyUrl = isVideo
                              ? story["video_resources"].first["src"]
                              : story["display_resources"].last["src"];
                          urls.add(storyUrl);
                          histItems.add(HistoryItemsCompanion.insert(
                            postId: story["id"],
                            coverImgUrl: story["display_url"],
                            imgUrls: storyUrl,
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
