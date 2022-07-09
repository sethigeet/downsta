import 'package:flutter/material.dart';

import 'package:drift/drift.dart' show Value;
import 'package:provider/provider.dart';

import 'package:downsta/services/services.dart';
import 'package:downsta/widgets/widgets.dart';
import 'package:downsta/screens/screens.dart';

class Videos extends StatefulWidget {
  const Videos({Key? key, required this.username}) : super(key: key);

  final String username;

  @override
  State<Videos> createState() => _VideosState();
}

class _VideosState extends State<Videos> {
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

      await api.get(
        queryHash: ApiQueryHashes.videos,
        params: {
          "id": await api.getUserId(widget.username),
          "after": endCursor
        },
        resExtractor: (res) => res["user"]["edge_felix_video_timeline"],
        cacheExtractor: (cache) => cache.videos[widget.username],
        referer: "https://www.instagram.com/${widget.username}/channel/",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final downloader = Provider.of<Downloader>(context, listen: false);
    final db = Provider.of<DB>(context, listen: false);
    final api = context.watch<Api>();
    final userVideos = api.cache.videos[widget.username];
    if (userVideos == null) {
      api.getUserId(widget.username).then((userId) => api.get(
            queryHash: ApiQueryHashes.videos,
            params: {"id": userId},
            resExtractor: (res) => res["user"]["edge_felix_video_timeline"],
            cacheExtractor: (cache) => cache.videos[widget.username],
            referer: "https://www.instagram.com/${widget.username}/channel/",
            initial: true,
            cacheInitializer: (cache) =>
                cache.videos[widget.username] = {"edges": [], "page_info": {}},
          ));

      return const Center(child: CircularProgressIndicator());
    }

    var videos = userVideos["edges"];

    if (videos.isEmpty) {
      return const NoContent(
        message: "This user has no videos!",
        icon: Icons.list_rounded,
      );
    }

    var pageInfo = userVideos["page_info"];
    var hasMoreVideos = pageInfo["has_next_page"];
    if (hasMoreVideos) {
      endCursor = pageInfo["end_cursor"];
    } else {
      endCursor = null;
    }

    return Stack(
      children: [
        GridView.builder(
            itemCount: hasMoreVideos ? videos.length + 1 : videos.length,
            controller: _scrollController,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              if (hasMoreVideos && index == videos.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final video = videos[index]["node"];
              final imageUrl = video["display_url"];
              final toBeDownloaded = toDownload.contains(index);
              return FutureBuilder<bool>(
                  future: db.isPostDownloaded(video["id"]),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final bool alreadyDownloaded = snap.data!;
                    return Hero(
                      tag: "video-${video["id"]}",
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
                              VideoScreen.routeName,
                              arguments: VideoScreenArguments(
                                video: video,
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

                        final videoIds =
                            toDownload.map((idx) => videos[idx]["node"]["id"]);
                        await Future.wait(
                            videoIds.map((id) => api.getVideoInfo(id)));
                        for (var id in videoIds) {
                          final video = api.cache.postsInfo[id];
                          final url = video["video_versions"].first["url"];
                          urls.add(url);

                          histItems.add(HistoryItemsCompanion.insert(
                            postId: video["id"].split("_").first,
                            coverImgBytes: Value(await downloader.getImgBytes(
                                video["image_versions2"]["candidates"]
                                    .first["url"])),
                            imgUrls: url,
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
