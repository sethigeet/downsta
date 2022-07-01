import 'package:downsta/screens/post.dart';
import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:downsta/utils.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    Key? key,
    required this.user,
  }) : super(key: key);

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final username = user["username"];
    final fullName = user["full_name"];
    final profilePicUrl = user["profile_pic_url"];
    final profilePicUrlHd = user["profile_pic_url_hd"];

    return Column(children: [
      Hero(
        tag: "profile-picture-$username",
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(context, PostScreen.routeName,
              arguments: PostScreenArguments(
                post: {
                  "display_url": profilePicUrlHd,
                  "id":
                      "$username-profile-pic-${DateTime.now().millisecondsSinceEpoch}",
                  "owner": {"username": username},
                },
                username: username,
              )),
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
