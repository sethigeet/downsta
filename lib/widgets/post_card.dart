import 'package:flutter/material.dart';

import 'package:drift/drift.dart' show Value;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import 'package:downsta/models/models.dart';
import 'package:downsta/services/services.dart';
import 'package:downsta/utils.dart';
import 'package:downsta/widgets/widgets.dart';
import 'package:downsta/screens/screens.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    Key? key,
    required this.post,
  }) : super(key: key);

  final Post post;

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DB>(context);
    final downloader = Provider.of<Downloader>(context);

    final username = post.username;

    return FutureBuilder<bool>(
        future: db.isPostDownloaded(post.id),
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
                          post.profilePicUrl,
                          cacheKey: getCacheKey(post.profilePicUrl),
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
                                final urls = post.urls;
                                downloader.download(urls, username);
                                db.saveItemToHistory(
                                    HistoryItemsCompanion.insert(
                                  postId: post.id,
                                  coverImgBytes: Value(await downloader
                                      .getImgBytes(post.displayUrl)),
                                  imgUrls: urls.join(","),
                                  username: username,
                                ));
                              },
                        icon: alreadyDownloaded
                            ? const Icon(Icons.download_done_rounded)
                            : const Icon(Icons.download_rounded),
                      )
                    ],
                  ),
                ),
              ),
              CachedImage(imageUrl: post.displayUrl),
            ]),
          );
        });
  }
}
