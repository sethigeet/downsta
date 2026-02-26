import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:downsta/services/services.dart';
import 'package:downsta/utils.dart';

class ProfileHeader extends StatefulWidget {
  final dynamic user;

  const ProfileHeader({Key? key, required this.user}) : super(key: key);

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

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Hero(
            tag: "profile-picture-$username",
            child: GestureDetector(
              onTap: () async {
                final snackbarController = ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  SnackBar(
                    content: const Text("Fetching high quality profile pic..."),
                    duration: const Duration(days: 365),
                  ),
                );
                final url = await api.getProfilePicUrl(username);
                snackbarController.close();
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                _showHdPicDialog(context, url, username);
              },
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.4),
                    ],
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.scaffoldBackgroundColor,
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.surface,
                    backgroundImage: CachedNetworkImageProvider(
                      profilePicUrl,
                      cacheKey: getCacheKey(profilePicUrl),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "@$username",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHdPicDialog(BuildContext context, String url, String username) {
    final theme = Theme.of(context);
    final downloader = Provider.of<Downloader>(context, listen: false);

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    cacheKey: getCacheKey(url),
                    fit: BoxFit.contain,
                    placeholder:
                        (context, _) => const SizedBox(
                          width: 200,
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: FloatingActionButton.small(
                    backgroundColor: theme.colorScheme.primary,
                    onPressed: () {
                      downloader.download([url], username);
                      Navigator.pop(context);
                    },
                    child: Icon(
                      Icons.download,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
