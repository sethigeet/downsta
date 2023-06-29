import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:downsta/utils.dart';

class CachedImage extends StatelessWidget {
  const CachedImage({Key? key, required this.imageUrl}) : super(key: key);
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheKey: getCacheKey(imageUrl),
      fit: BoxFit.cover,
      progressIndicatorBuilder: (context, url, downloadProgress) => Container(
        color: theme.colorScheme.background,
        child: Center(
          child: CircularProgressIndicator(value: downloadProgress.progress),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: theme.colorScheme.background,
        child: const Center(child: Icon(Icons.error)),
      ),
    );
  }
}
