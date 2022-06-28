import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:downsta/screens/history.dart';
import 'package:downsta/services/downloader.dart';

class DownloadStatusIndicator extends StatelessWidget {
  const DownloadStatusIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final downloader = Provider.of<Downloader>(context);

    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: TextButton(
        onPressed: () {
          Navigator.pushNamed(context, HistoryScreen.routeName);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.downloading, size: 30),
            downloader.running
                ? Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const CircularProgressIndicator(),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
