import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:drift/drift.dart' show Value;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:downsta/services/services.dart';
import 'package:downsta/widgets/widgets.dart';
import 'package:downsta/screens/screens.dart';

class HighlightsScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

class Stories extends StatefulWidget {
  const Stories(
      {Key? key,
      required this.username,
      this.showHighlights = true,
      this.stories})
      : super(key: key);

  final String username;
  final bool showHighlights;
  final dynamic stories;

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
    final stories = widget.stories ?? api.cache.stories[widget.username];
    dynamic highlights;
    if (widget.showHighlights) {
      highlights = api.cache.highlights[widget.username];
    }
    if (stories == null || (widget.showHighlights && highlights == null)) {
      api.getStories(widget.username);
      if (widget.showHighlights) {
        api.getHighlights(widget.username);
      }
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    List<dynamic> items = stories.isEmpty ? [] : stories["items"];

    if (items.isEmpty && (widget.showHighlights && highlights.isEmpty)) {
      return const NoContent(
        message: "This user has no stories!",
        icon: Icons.list_rounded,
      );
    }

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            if (widget.showHighlights)
              SliverToBoxAdapter(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 90,
                  child: ScrollConfiguration(
                    behavior: HighlightsScrollBehavior(),
                    child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 5),
                        itemExtent: 75,
                        itemCount: highlights.length,
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final highlight = highlights[index]["node"];
                          return GestureDetector(
                            onTap: () => Navigator.of(context)
                                .pushNamed(HighlightItemsScreen.routeName,
                                    arguments: HighlightItemsScreenArguments(
                                      highlight: highlight,
                                      username: widget.username,
                                    )),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: CachedNetworkImageProvider(
                                      highlight["cover_media_cropped_thumbnail"]
                                          ["url"]),
                                ),
                                Text(highlight["title"], maxLines: 1)
                              ],
                            ),
                          );
                        }),
                  ),
                ),
              ),
            if (widget.showHighlights)
              const SliverToBoxAdapter(
                child: Divider(height: 5),
              ),
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, childAspectRatio: 9 / 16),
              delegate: SliverChildBuilderDelegate(
                childCount: items.length,
                (context, index) {
                  final story = items[index];
                  final imageUrl = story["display_url"];
                  final toBeDownloaded = toDownload.contains(index);
                  return FutureBuilder<bool>(
                      future: db.isPostDownloaded(story["id"]),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
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
                                            alreadyDownloaded:
                                                alreadyDownloaded,
                                          )
                                        : Container())
                              ],
                            ),
                          ),
                        );
                      });
                },
              ),
            )
          ],
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
                          final story = items[idx];
                          final isVideo = story["is_video"];
                          String storyUrl = isVideo
                              ? story["video_resources"].first["src"]
                              : story["display_resources"].last["src"];
                          urls.add(storyUrl);
                          histItems.add(HistoryItemsCompanion.insert(
                            postId: story["id"],
                            coverImgBytes: Value(await downloader
                                .getImgBytes(story["display_url"])),
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
