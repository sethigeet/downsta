import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import 'package:downsta/models/models.dart';
import 'package:downsta/screens/screens.dart';
import 'package:downsta/services/services.dart';
import 'package:downsta/utils.dart';

class ProfileHeader extends StatefulWidget {
  const ProfileHeader({
    Key? key,
    required this.user,
  }) : super(key: key);

  final Profile user;

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final api = Provider.of<Api>(context, listen: false);

    final username = widget.user.username;
    final fullName = widget.user.fullName;
    final profilePicUrl = widget.user.profilePicUrl;

    return Column(children: [
      Hero(
        tag: "profile-picture-$username",
        child: GestureDetector(
          onTap: () async {
            final snackbarController =
                ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Fetching high quality profile pic..."),
                backgroundColor: Theme.of(context).colorScheme.primary,
                duration: const Duration(days: 365),
              ),
            );
            final url = await api.getProfilePicUrl(username);
            snackbarController.close();
            _gotoPostScreen(url);
          },
          child: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(
              profilePicUrl,
              cacheKey: getCacheKey(profilePicUrl),
            ),
            backgroundColor: theme.backgroundColor,
            radius: 50,
          ),
        ),
      ),
      const SizedBox(height: 10),
      Text(fullName,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      Text("@$username",
          style: const TextStyle(fontSize: 14, color: Colors.white70)),
    ]);
  }

  void _gotoPostScreen(String url) {
    final username = widget.user.username;
    Navigator.pushNamed(context, PostScreen.routeName,
        arguments: PostScreenArguments(
          post: Post({
            "display_url": url,
            "id":
                "$username-profile-pic-${DateTime.now().millisecondsSinceEpoch}",
            "is_video": false,
          }),
          username: username,
        ));
  }
}
