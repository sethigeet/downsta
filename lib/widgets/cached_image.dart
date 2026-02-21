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
      progressIndicatorBuilder:
          (context, url, downloadProgress) => Container(
            color: theme.colorScheme.surface,
            child: Center(
              child: _ShimmerPulse(progress: downloadProgress.progress),
            ),
          ),
      errorWidget:
          (context, url, error) => Container(
            color: theme.colorScheme.surface,
            child: Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
                size: 32,
              ),
            ),
          ),
    );
  }
}

class _ShimmerPulse extends StatefulWidget {
  const _ShimmerPulse({this.progress});
  final double? progress;

  @override
  State<_ShimmerPulse> createState() => _ShimmerPulseState();
}

class _ShimmerPulseState extends State<_ShimmerPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = 0.15 + (_controller.value * 0.25);
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withValues(alpha: opacity),
          ),
          child:
              widget.progress != null
                  ? CircularProgressIndicator(
                    value: widget.progress,
                    strokeWidth: 2.5,
                    color: theme.colorScheme.primary,
                  )
                  : null,
        );
      },
    );
  }
}
