import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:downsta/utils.dart';
import 'package:downsta/screens/profile.dart';

class UserCard extends StatelessWidget {
  const UserCard({
    Key? key,
    required this.fullName,
    required this.username,
    required this.profilePicUrl,
  }) : super(key: key);

  final String fullName;
  final String username;
  final String profilePicUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      child: Card(
        child: ListTile(
          title: Text(fullName),
          subtitle: Text("@$username"),
          leading: Hero(
            tag: "profile-picture-$username",
            child: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(
                profilePicUrl,
                cacheKey: getCacheKey(profilePicUrl),
              ),
              backgroundColor: theme.backgroundColor,
            ),
          ),
        ),
      ),
      onTap: () {
        Navigator.pushNamed(
          context,
          ProfileScreen.routeName,
          arguments: ProfileScreenArguments(username: username),
        );
      },
    );
  }
}
