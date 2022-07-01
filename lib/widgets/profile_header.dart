import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import 'package:downsta/screens/screens.dart';
import 'package:downsta/services/services.dart';
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

    final api = Provider.of<Api>(context, listen: false);

    final username = user["username"];
    final fullName = user["full_name"];
    final profilePicUrl = user["profile_pic_url"];

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

            // ignore: use_build_context_synchronously
            Navigator.pushNamed(context, PostScreen.routeName,
                arguments: PostScreenArguments(
                  post: {
                    "display_url": url,
                    "id":
                        "$username-profile-pic-${DateTime.now().millisecondsSinceEpoch}",
                  },
                  username: username,
                ));
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
}
