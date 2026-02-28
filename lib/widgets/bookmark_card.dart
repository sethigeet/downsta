import 'package:flutter/material.dart';

import 'package:downsta/screens/screens.dart';
import 'package:downsta/services/services.dart';

class BookmarkCard extends StatelessWidget {
  const BookmarkCard({Key? key, required this.item, required this.onRemove})
    : super(key: key);

  final Bookmark item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.cardTheme.color,
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: 56,
                height: 56,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.person_outline_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
            ),
            title: Text(
              item.username,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.bookmark_remove_outlined,
                color: theme.colorScheme.error.withValues(alpha: 0.7),
                size: 20,
              ),
              onPressed: onRemove,
              tooltip: "Remove bookmark",
              visualDensity: VisualDensity.compact,
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                ProfileScreen.routeName,
                arguments: ProfileScreenArguments(username: item.username),
              );
            },
          ),
        ),
      ),
    );
  }
}
