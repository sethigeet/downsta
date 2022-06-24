import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

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

    return GridView.builder(
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
          return Hero(
            tag: "post-${post["id"]}",
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  "/post",
                  arguments: PostScreenArguments(
                      post: post, username: post["owner"]["username"]),
                );
              },
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                cacheKey: getCacheKey(imageUrl),
                fit: BoxFit.cover,
                progressIndicatorBuilder: (context, url, downloadProgress) =>
                    Container(
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
            ),
          );
        });
  }
}
