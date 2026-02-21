import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:downsta/screens/screens.dart';
import 'package:downsta/services/services.dart';

class DownloadStatusIndicator extends StatefulWidget {
  const DownloadStatusIndicator({Key? key}) : super(key: key);

  @override
  State<DownloadStatusIndicator> createState() =>
      _DownloadStatusIndicatorState();
}

class _DownloadStatusIndicatorState extends State<DownloadStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final downloader = Provider.of<Downloader>(context);

    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: IconButton(
        onPressed: () {
          Navigator.pushNamed(context, HistoryScreen.routeName);
        },
        icon: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                if (downloader.running)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withValues(
                        alpha: 0.1 + (_pulseController.value * 0.15),
                      ),
                    ),
                  ),
                Icon(
                  downloader.running
                      ? Icons.downloading_rounded
                      : Icons.download_done_rounded,
                  size: 22,
                  color:
                      downloader.running
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                ),
                if (downloader.running)
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
