import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:downsta/models/models.dart';
import 'package:downsta/services/api.dart';

class Feed extends StatefulWidget {
  const Feed({Key? key}) : super(key: key);

  @override
  State<Feed> createState() => _FeedState();
}

class _FeedState extends State<Feed> {
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

      await api.get<Post>(
          queryHash: ApiQueryHashes.feed,
          params: {
            'fetch_media_item_count': 12,
            'fetch_media_item_cursor': endCursor,
            // 'fetch_comment_count': 4,
            // 'fetch_like': 10,
            'has_stories': false
          },
          resExtractor: (res) => res["user"]["edge_web_feed_timeline"],
          cacheExtractor: (cache) => cache.feed!,
          nodeConverter: (node) => Post(node));
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = context.watch<Api>();
    if (api.cache.feed == null) {
      api.getUserId(api.username).then((userId) => api.get<Post>(
            queryHash: ApiQueryHashes.feed,
            params: {
              'fetch_media_item_count': 12,
              // 'fetch_media_item_cursor': ,
              // 'fetch_comment_count': 4,
              // 'fetch_like': 10,
              'has_stories': false
            },
            resExtractor: (res) => res["user"]["edge_web_feed_timeline"],
            cacheExtractor: (cache) => cache.feed,
            nodeConverter: (node) =>
                acceptedPostTypes.contains(node["__typename"])
                    ? Post(node)
                    : null,
            initial: true,
            cacheInitializer: (cache) =>
                cache.feed = PaginatedResponse<Post>.empty(),
          ));

      return Scaffold(
        appBar: AppBar(
          title: const Text("Downsta"),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final posts = api.cache.feed!.edges;
    final hasMorePosts = api.cache.feed!.hasMoreEdges;
    endCursor = api.cache.feed!.endCursor;

    return ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        itemCount: posts.length + (hasMorePosts ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == posts.length) {
            return const Center(child: CircularProgressIndicator());
          }

          // var post = posts[index];
          // return PostCard(post: post);
          return const Text("TODO :)");
        });
  }
}
