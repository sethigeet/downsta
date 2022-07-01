import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:downsta/screens/screens.dart';
import 'package:downsta/services/services.dart';
import 'package:downsta/widgets/widgets.dart';
import 'package:downsta/helpers/helpers.dart';
import 'package:downsta/utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static const routeName = "/home";

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    var me = api.cache.userInfo[api.username];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Downsta"),
        actions: [
          Builder(builder: (context) {
            return IconButton(
              onPressed: () => showSearch(
                context: context,
                delegate: SearchProfiles(api: api),
              ),
              icon: const Icon(Icons.search),
            );
          }),
          const DownloadStatusIndicator()
        ],
      ),
      drawer: MyDrawer(user: me),
      body: ListView.builder(
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
          }),
    );
  }
}

class MyDrawer extends StatelessWidget {
  const MyDrawer({
    Key? key,
    required this.user,
  }) : super(key: key);

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final api = context.watch<Api>();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
            ),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(
                    user["profile_pic_url"],
                    cacheKey: getCacheKey(user["profile_pic_url"]),
                  ),
                  backgroundColor: theme.backgroundColor,
                  radius: 35,
                ),
                const SizedBox(height: 15),
                FutureBuilder(
                  future: api.db.getLoggedInUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return ErrorDisplay(message: "${snapshot.error}");
                    } else if (snapshot.hasData) {
                      return DropdownButton<String>(
                        value: user["username"],
                        iconEnabledColor: theme.colorScheme.onPrimary,
                        selectedItemBuilder: (context) {
                          return (snapshot.data as List<String>)
                              .map((username) => DropdownMenuItem(
                                    value: username,
                                    child: Text(
                                      username,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ))
                              .toList();
                        },
                        // text: theme.colorScheme.onPrimary,
                        icon: const Icon(Icons.person),
                        items: [
                          ...(snapshot.data as List<String>)
                              .map((username) => DropdownMenuItem(
                                    value: username,
                                    child: Text(username),
                                  ))
                              .toList(),
                          DropdownMenuItem(
                            value: "add-user",
                            child: Row(children: const [
                              Icon(Icons.add),
                              Text("Add User")
                            ]),
                          )
                        ],
                        onChanged: (newVal) {
                          if (newVal == null) {
                            return;
                          }
                          if (newVal == "add-user") {
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const LoginScreen(addingUser: true),
                                ));
                            return;
                          }

                          // Switch the user
                          Navigator.pop(context);
                          api.switchUser(newVal);
                        },
                      );
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                )
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Not Implemented!"),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: const [
                          Text("TODO :)"),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text("Okay"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text("Download History"),
            onTap: () {
              Navigator.pushNamed(context, HistoryScreen.routeName);
            },
          ),
        ],
      ),
    );
  }
}
