import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:downsta/services/api.dart';
import 'package:downsta/widgets/widgets.dart';

class Following extends StatefulWidget {
  const Following({Key? key}) : super(key: key);

  @override
  State<Following> createState() => _FollowingState();
}

class _FollowingState extends State<Following> {
  final _scrollController = ScrollController();
  String? endCursor;

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

      await api.get(
        queryHash: ApiQueryHashes.following,
        params: {"id": await api.getUserId(api.username), "after": endCursor},
        resExtractor: (res) => res["user"]["edge_follow"],
        cacheExtractor: (cache) => cache.following!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = context.watch<Api>();
    if (api.cache.following == null) {
      api.getUserId(api.username).then((userId) => api.get(
            queryHash: ApiQueryHashes.following,
            params: {"id": userId},
            resExtractor: (res) => res["user"]["edge_follow"],
            cacheExtractor: (cache) => cache.following,
            initial: true,
            cacheInitializer: (cache) => cache.following = {"edges": []},
          ));

      return Scaffold(
        appBar: AppBar(
          title: const Text("Downsta"),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    List<dynamic> users = api.cache.following!["edges"] ?? [];
    var pageInfo = api.cache.following!["page_info"];
    var hasMorePosts = pageInfo["has_next_page"];
    if (hasMorePosts) {
      endCursor = pageInfo["end_cursor"];
    } else {
      endCursor = null;
    }

    return ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        itemCount: users.length + (hasMorePosts ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == users.length) {
            return const Center(child: CircularProgressIndicator());
          }

          var user = users[index]["node"];
          return UserCard(
              fullName: user["full_name"],
              username: user["username"],
              profilePicUrl: user["profile_pic_url"]);
        });
  }
}
