import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:downsta/services/api.dart';
import 'package:downsta/widgets/profile_header.dart';
import 'package:downsta/widgets/posts.dart';

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
    final userInfo = api.userInfo[username];
    if (userInfo == null) {
      api.getUserInfo(username);

      return Scaffold(
        appBar: AppBar(
          title: Text(username),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(username),
      ),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: ProfileHeader(
            username: username,
            fullName: userInfo["full_name"],
            profilePicUrl: userInfo["profile_pic_url"],
            profilePicUrlHd: userInfo["profile_pic_url_hd"],
          ),
        ),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.photo), text: "Posts"),
            Tab(icon: Icon(Icons.timelapse), text: "Stories"),
            Tab(icon: Icon(Icons.video_collection_rounded), text: "Reels"),
            Tab(icon: Icon(Icons.tv), text: "IGTV"),
          ],
        ),
        const SizedBox(height: 20),
        Flexible(
          child: TabBarView(controller: _tabController, children: [
            Posts(username: username),
            const Center(child: Text("Stories :)")),
            const Center(child: Text("Reels :)")),
            const Center(child: Text("IGTV :)")),
          ]),
        ),
      ]),
    );
  }
}
