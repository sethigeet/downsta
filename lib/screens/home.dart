import 'dart:io';

import 'package:flutter/material.dart';

import 'package:drift/drift.dart' show Value;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:downsta/models/models.dart';
import 'package:downsta/services/services.dart';
import 'package:downsta/helpers/helpers.dart';
import 'package:downsta/utils.dart';
import 'package:downsta/screens/screens.dart';
import 'package:downsta/widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static const routeName = "/home";

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  @override
  void initState() {
    super.initState();

    if (Platform.isAndroid) {
      ShareService()
        ..onDataReceived = _handleSharedData
        ..getSharedData().then(_handleSharedData);
    }
  }

  void _handleSharedData(String sharedData) async {
    if (sharedData == "") {
      return;
    }

    try {
      final shortCode = sharedData.split("/")[4];
      final api = Provider.of<Api>(context, listen: false);
      final downloader = Provider.of<Downloader>(context, listen: false);
      final db = Provider.of<DB>(context, listen: false);
      final postInfo = await api.getPostInfo(shortCode);

      if (postInfo == null) {
        showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text("Unable to retreive post!"),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: const [
                        Text(
                            "You may not follow this account or you have been blocked by this account!"),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text("Okay"),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ));
        return;
      }

      final coverImgUrl = postInfo.displayUrl;
      final urls = postInfo.urls;
      final username = postInfo.username;
      downloader.download(urls, username);
      downloader
          .getImgBytes(coverImgUrl)
          .then((b) => db.saveItemToHistory(HistoryItemsCompanion.insert(
                postId: postInfo.id,
                username: username,
                coverImgBytes: Value(b),
                imgUrls: urls.join(","),
              )));
    } catch (err) {
      showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text("Invalid URL shared!"),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: [
                      const Text("URL: "),
                      Text(sharedData),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    child: const Text("Okay"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = context.watch<Api>();
    var me = api.cache.profiles[api.username];
    if (me == null) {
      api.getUserInfo(api.username);

      return Scaffold(
        appBar: AppBar(
          title: const Text("Downsta"),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (newIndex) => setState(() => index = newIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.person), label: "Following"),
          NavigationDestination(icon: Icon(Icons.feed_rounded), label: "Feed"),
        ],
      ),
      body: [
        const Following(),
        const Center(child: Text("Feed!")),
      ][index],
    );
  }
}

class MyDrawer extends StatelessWidget {
  const MyDrawer({
    Key? key,
    required this.user,
  }) : super(key: key);

  final Profile user;

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
                    user.profilePicUrl,
                    cacheKey: getCacheKey(user.profilePicUrl),
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
                        value: user.username,
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
                          Navigator.pop(context);
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
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () async {
              final snackbarController =
                  ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Logging out..."),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  duration: const Duration(days: 365),
                ),
              );
              await api.logout(user.username);
              snackbarController.close();
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
              // ignore: use_build_context_synchronously
              Navigator.pushReplacementNamed(context, LoginScreen.routeName);
            },
          ),
        ],
      ),
    );
  }
}
