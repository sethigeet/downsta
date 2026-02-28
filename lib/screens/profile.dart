import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:downsta/services/services.dart';
import 'package:downsta/widgets/widgets.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = "/profile";

  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args =
        ModalRoute.of(context)!.settings.arguments as ProfileScreenArguments;
    final username = args.username;

    final api = context.watch<Api>();
    final db = Provider.of<DB>(context, listen: false);
    final user = api.cache.profiles[username];
    if (user == null) {
      api.getUserInfo(username);

      return Scaffold(
        appBar: AppBar(title: Text(username)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isPrivate = user.isPrivate && !user.followedByViewer;
    final isBookmarked = db.isBookmarkedCache[username] ?? false;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            snap: false,
            floating: true,
            title: Text(username),
            actions: [
              IconButton(
                icon: Icon(
                  isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  color: isBookmarked
                      ? theme.colorScheme.primary
                      : null,
                ),
                tooltip: isBookmarked ? "Remove bookmark" : "Bookmark profile",
                onPressed: () async {
                  if (isBookmarked) {
                    await db.removeBookmarkByUsername(username);
                  } else {
                    await db.addBookmark(
                      BookmarksCompanion.insert(
                        username: username,
                      ),
                    );
                  }
                  setState(() {});
                },
              ),
              const DownloadStatusIndicator(),
            ],
          ),
          SliverToBoxAdapter(child: ProfileHeader(user: user)),
          if (isPrivate)
            const SliverFillRemaining(
              child: NoContent(
                message: "This account is private",
                icon: Icons.lock_outline_rounded,
              ),
            ),
          if (!isPrivate)
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on_rounded), text: "Posts"),
                    Tab(
                      icon: Icon(Icons.auto_awesome_rounded),
                      text: "Stories",
                    ),
                    Tab(icon: Icon(Icons.movie_filter_rounded), text: "Reels"),
                    Tab(icon: Icon(Icons.smart_display_rounded), text: "IGTV"),
                  ],
                ),
                theme.scaffoldBackgroundColor,
              ),
            ),
          if (!isPrivate)
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  Posts(username: username),
                  Stories(username: username),
                  Reels(username: username),
                  Videos(username: username),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, this._backgroundColor);

  final TabBar _tabBar;
  final Color _backgroundColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: _backgroundColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class ProfileScreenArguments {
  final String username;
  ProfileScreenArguments({required this.username});
}
