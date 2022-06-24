import 'package:downsta/screens/post.dart';
import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:downsta/utils.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    Key? key,
    required this.fullName,
    required this.username,
    required this.profilePicUrl,
    required this.profilePicUrlHd,
  }) : super(key: key);

  final String username;
  final String fullName;
  final String profilePicUrl;
  final String profilePicUrlHd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(children: [
      Hero(
        tag: "profile-picture-$username",
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(context, PostScreen.routeName,
              arguments: PostScreenArguments(
                  post: {"display_url": profilePicUrlHd}, username: username)),
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
}
