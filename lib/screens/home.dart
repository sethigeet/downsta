import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:downsta/widgets/user_card.dart';
import 'package:downsta/services/api.dart';
import 'package:downsta/utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static const routeName = "/home";

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final api = context.watch<Api>();
    if (api.following == null) {
      api.getFollowing();

      return Scaffold(
        appBar: AppBar(
          title: const Text("Downsta"),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    var users = api.following ?? [];
    var me = api.userInfo[api.username];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Downsta"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Row(
                children: [
                  me != null
                      ? CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(
                            me["profile_pic_url"],
                            cacheKey: getCacheKey(me["profile_pic_url"]),
                          ),
                          backgroundColor: theme.backgroundColor,
                          radius: 50,
                        )
                      : const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
            const ListTile(
              leading: Icon(Icons.message),
              title: Text('Messages'),
            ),
          ],
        ),
      ),
      body: ListView.builder(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          itemCount: users.length,
          itemBuilder: (context, index) {
            var user = users[index];
            return UserCard(
                fullName: user["full_name"],
                username: user["username"],
                profilePicUrl: user["profile_pic_url"]);
          }),
    );
  }
}
