import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  void _handleSharedData(String sharedData) {
    if (sharedData.isEmpty) return;
    _downloadFromUrl(sharedData);
  }

  Future<void> _downloadFromUrl(String url) async {
    try {
      final shortCode = url.split("/")[4];
      final api = Provider.of<Api>(context, listen: false);
      final downloader = Provider.of<Downloader>(context, listen: false);
      final db = Provider.of<DB>(context, listen: false);
      final postInfo = await api.getPostInfo(shortCode);

      if (postInfo == null) {
        if (!mounted) return;
        showDialog<void>(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Unable to retrieve post!"),
            content: const SingleChildScrollView(
              child: ListBody(
                children: [
                  Text(
                    "You may not follow this account or you have been blocked by this account!",
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Okay"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
        return;
      }

      final coverImgUrl = postInfo.displayUrl;
      final urls = postInfo.urls;
      final username = postInfo.username;
      downloader.download(urls, username);
      downloader.getImgBytes(coverImgUrl).then(
        (b) => db.saveItemToHistory(
          HistoryItemsCompanion.insert(
            postId: postInfo.id,
            username: username,
            coverImgBytes: Value(b),
            imgUrls: urls.join(","),
          ),
        ),
      );
    } catch (err) {
      if (!mounted) return;
      showDialog<void>(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Invalid URL!"),
          content: SingleChildScrollView(
            child: ListBody(
              children: [const Text("URL: "), Text(url)],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Okay"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  void _showPasteLinkDialog() {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Download from URL"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "https://www.instagram.com/p/...",
                prefixIcon: Icon(Icons.link_rounded),
              ),
              autofocus: true,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.pop(context);
                  _downloadFromUrl(value);
                }
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null && data!.text!.isNotEmpty) {
                    controller.text = data.text!;
                    controller.selection = TextSelection.fromPosition(
                      TextPosition(offset: controller.text.length),
                    );
                  }
                },
                icon: const Icon(Icons.content_paste_rounded, size: 18),
                label: const Text("Paste from clipboard"),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                _downloadFromUrl(controller.text);
              }
            },
            child: const Text("Download"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = context.watch<Api>();
    var me = api.cache.profiles[api.username];
    if (me == null) {
      api.getUserInfo(api.username);

      return Scaffold(
        appBar: AppBar(title: const Text("Downsta")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Downsta"),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () => showSearch(
                  context: context,
                  delegate: SearchProfiles(api: api),
                ),
                icon: const Icon(Icons.search_rounded),
              );
            },
          ),
          const DownloadStatusIndicator(),
        ],
      ),
      drawer: MyDrawer(user: me),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPasteLinkDialog,
        tooltip: "Download from URL",
        child: const Icon(Icons.link_rounded),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (newIndex) => setState(() => index = newIndex),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: "Following",
          ),
          NavigationDestination(
            icon: Icon(Icons.dynamic_feed_outlined),
            selectedIcon: Icon(Icons.dynamic_feed_rounded),
            label: "Feed",
          ),
        ],
      ),
      body: [const Following(), const Feed()][index],
    );
  }
}

class MyDrawer extends StatelessWidget {
  const MyDrawer({Key? key, required this.user}) : super(key: key);

  final Profile user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final api = context.watch<Api>();

    return Drawer(
      child: Column(
        children: [
          // ── Drawer Header ──
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.15),
                  theme.colorScheme.surface,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.drawerTheme.backgroundColor,
                    ),
                    child: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(
                        user.profilePicUrl,
                        cacheKey: getCacheKey(user.profilePicUrl),
                      ),
                      backgroundColor: theme.colorScheme.surface,
                      radius: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.fullName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                // ── User Switcher ──
                FutureBuilder(
                  future: api.db.getLoggedInUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return ErrorDisplay(message: "${snapshot.error}");
                    } else if (snapshot.hasData) {
                      return DropdownButton<String>(
                        value: user.username,
                        underline: const SizedBox.shrink(),
                        isDense: true,
                        iconEnabledColor: theme.colorScheme.primary,
                        icon: const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.unfold_more_rounded, size: 18),
                        ),
                        selectedItemBuilder: (context) {
                          return (snapshot.data as List<String>)
                              .map(
                                (username) => DropdownMenuItem(
                                  value: username,
                                  child: Text(
                                    "@$username",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                              .toList();
                        },
                        items: [
                          ...(snapshot.data as List<String>)
                              .map(
                                (username) => DropdownMenuItem(
                                  value: username,
                                  child: Text(
                                    username,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              )
                              .toList(),
                          DropdownMenuItem(
                            value: "add-user",
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Add User",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                                builder:
                                    (_) => const LoginScreen(addingUser: true),
                              ),
                            );
                            return;
                          }

                          // Switch the user
                          Navigator.pop(context);
                          api.switchUser(newVal);
                        },
                      );
                    } else {
                      return const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Menu Items ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.settings_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text("Settings", style: theme.textTheme.bodyLarge),
                  onTap: () {
                    Navigator.pushNamed(context, SettingsScreen.routeName);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.history_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    "Download History",
                    style: theme.textTheme.bodyLarge,
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, HistoryScreen.routeName);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.logout_rounded,
                    color: theme.colorScheme.error.withValues(alpha: 0.7),
                  ),
                  title: Text(
                    "Logout",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.error.withValues(alpha: 0.7),
                    ),
                  ),
                  onTap: () async {
                    final snackbarController = ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text("Logging out..."),
                        duration: Duration(days: 365),
                      ),
                    );
                    await api.logout(user.username);
                    snackbarController.close();
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                    // ignore: use_build_context_synchronously
                    Navigator.pushReplacementNamed(
                      // ignore: use_build_context_synchronously
                      context,
                      LoginScreen.routeName,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
