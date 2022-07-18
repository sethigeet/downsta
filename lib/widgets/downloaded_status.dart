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

  static const _duration = Duration(milliseconds: 100);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryBg = theme.colorScheme.primary;
    final primaryFg = theme.colorScheme.onPrimary;

    final showCheck = toBeDownloaded || alreadyDownloaded;
    final bgColor = alreadyDownloaded
        ? Colors.grey.shade600.withOpacity(0.6)
        : primaryBg.withOpacity(0.6);

    final fgColor = alreadyDownloaded ? Colors.black54 : primaryFg;

    return AnimatedOpacity(
      opacity: show ? 1 : 0,
      duration: _duration,
      child: AnimatedContainer(
        duration: _duration,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: showCheck
              ? null
              : Border.all(
                  color: primaryBg,
                  width: 2,
                ),
          color: showCheck ? bgColor : null,
        ),
        height: 25,
        width: 25,
        child: showCheck
            ? Icon(
                alreadyDownloaded ? Icons.check : Icons.download_done_rounded,
                color: fgColor,
              )
            : null,
      ),
    );
  }
}
