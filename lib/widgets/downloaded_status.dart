import 'package:flutter/material.dart';

class DownloadedStatus extends StatelessWidget {
  const DownloadedStatus({
    Key? key,
    required this.show,
    required this.toBeDownloaded,
    required this.alreadyDownloaded,
  }) : super(key: key);

  final bool show;
  final bool toBeDownloaded;
  final bool alreadyDownloaded;

  static const _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final showCheck = toBeDownloaded || alreadyDownloaded;
    final bgColor =
        alreadyDownloaded
            ? Colors.black54
            : theme.colorScheme.primary.withValues(alpha: 0.85);
    final fgColor =
        alreadyDownloaded ? Colors.white70 : theme.colorScheme.onPrimary;

    return AnimatedOpacity(
      opacity: show ? 1 : 0,
      duration: _duration,
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: _duration,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: showCheck ? bgColor : Colors.black38,
          border:
              showCheck
                  ? null
                  : Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                    width: 2,
                  ),
          boxShadow:
              showCheck
                  ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                  : null,
        ),
        height: 26,
        width: 26,
        child:
            showCheck
                ? Icon(
                  alreadyDownloaded ? Icons.download_done_rounded : Icons.check,
                  color: fgColor,
                  size: 18,
                )
                : null,
      ),
    );
  }
}
