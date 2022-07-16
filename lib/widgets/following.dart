import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:downsta/models/models.dart';
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

      await api.get<Profile>(
          queryHash: ApiQueryHashes.following,
          params: {"id": await api.getUserId(api.username), "after": endCursor},
          resExtractor: (res) => res["user"]["edge_follow"],
          cacheExtractor: (cache) => cache.following!,
          nodeConverter: (node) => Profile(node));
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = context.watch<Api>();
    if (api.cache.following == null) {
      api.getUserId(api.username).then((userId) => api.get<Profile>(
            queryHash: ApiQueryHashes.following,
            params: {"id": userId},
            resExtractor: (res) => res["user"]["edge_follow"],
            cacheExtractor: (cache) => cache.following,
            nodeConverter: (node) => Profile(node),
            initial: true,
            cacheInitializer: (cache) =>
                cache.following = PaginatedResponse<Profile>.empty(),
          ));

      return Scaffold(
        appBar: AppBar(
          title: const Text("Downsta"),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final users = api.cache.following!.edges;
    final hasMorePosts = api.cache.following!.hasMoreEdges;
    endCursor = api.cache.following!.endCursor;

    return ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        itemCount: users.length + (hasMorePosts ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == users.length) {
            return const Center(child: CircularProgressIndicator());
          }

          var user = users[index];
          return UserCard(
              fullName: user.fullName,
              username: user.username,
              profilePicUrl: user.profilePicUrl);
        });
  }
}
