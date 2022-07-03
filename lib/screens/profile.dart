import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:downsta/widgets/widgets.dart';
import 'package:downsta/services/services.dart';

class ProfileScreenArguments {
  String username;

  ProfileScreenArguments({required this.username});
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  static const routeName = "/profile";

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as ProfileScreenArguments;
    final username = args.username;

    final api = context.watch<Api>();
    final userInfo = api.cache.userInfo[username];
    if (userInfo == null) {
      api.getUserInfo(username);

      return Scaffold(
        appBar: AppBar(
          title: Text(username),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isPrivate = userInfo["is_private"] == true &&
        userInfo["followed_by_viewer"] != true;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            snap: false,
            floating: true,
            title: Text(username),
            actions: const [DownloadStatusIndicator()],
          ),
          SliverToBoxAdapter(
            child: ProfileHeader(user: userInfo),
          ),
          if (!isPrivate)
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.photo), text: "Posts"),
                    Tab(icon: Icon(Icons.timelapse), text: "Stories"),
                    Tab(
                        icon: Icon(Icons.video_collection_rounded),
                        text: "Reels"),
                    Tab(icon: Icon(Icons.tv), text: "IGTV"),
                  ],
                ),
              ),
            ),
          SliverFillRemaining(
            child: isPrivate
                ? const NoContent(
                    message: "This profile is private!",
                    icon: Icons.privacy_tip_outlined,
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      Posts(username: username),
                      const Center(child: Text("Stories :)")),
                      Reels(username: username),
                      const Center(child: Text("IGTV :)")),
                    ],
                  ),
          )
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
