import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:downsta/globals.dart';
import 'package:downsta/services/services.dart';
import 'package:downsta/utils.dart';

class DownloadItem {
  String url;
  String filename;

  DownloadItem(this.url, this.filename);
}

class Downloader with ChangeNotifier, DiagnosticableTreeMixin {
  final ImageCacheManager cacheManager = DefaultCacheManager();
  final String downloadDir;
  final DB db;
  Queue<DownloadItem> queue;
  bool running = false;

  static const batchSize = 5;

  Downloader(this.queue, this.downloadDir, this.db);

  static Future<Downloader> create(DB db) async {
    final dir = await getDownloadsDir();

    return Downloader(Queue(), "$dir/downsta", db);
  }

  void download(List<String> urls, String username) {
    queue.addAll(urls.map((url) {
      final uri = Uri.parse(url);
      final nameSegs = uri.pathSegments.last.split("_");
      var ext = nameSegs.last.split(".").last;
      // NOTE: For some reason, instagram names `jpg` files with the `webp` extension
      //       So, replace `webp` with `jpg`
      ext = ext == "webp" ? "jpg" : ext;
      ext = ext == "jpeg" ? "jpg" : ext;

      var uniqueId = nameSegs[nameSegs.length - 2];
      if (uniqueId == "video") {
        uniqueId = uri.queryParameters["vs"]!.split("_").first;
      }

      // File Name -> <username>_<unique_id>.<file_extension>
      return DownloadItem(
        url,
        "${username}_$uniqueId.$ext",
      );
    }).toList());

    if (!running) {
      _startDownloads();
    }
  }

  void _startDownloads() async {
    await Directory(downloadDir).create();

    running = true;
    notifyListeners();

    List<Future> futures = [];
    while (queue.isNotEmpty) {
      final item = queue.removeFirst();
      futures.add(_download(item));

      if (futures.length == batchSize) {
        await Future.wait(futures);
        futures.clear();
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
      futures.clear();
    }

    _notify();

    running = false;
    notifyListeners();
  }

  Future<void> _download(DownloadItem item) async {
    final url = item.url;
    var stream = cacheManager.getImageFile(url, key: getCacheKey(url));

    await for (var result in stream) {
      if (result is DownloadProgress) {
        // TODO: handle progress here!
      }

      if (result is FileInfo) {
        var file = result.file;
        await file.copy("$downloadDir/${item.filename}");
      }
    }
  }

  Future<Uint8List?> getImgBytes(String url) async {
    var stream = cacheManager.getImageFile(url, key: getCacheKey(url));

    await for (var result in stream) {
      if (result is FileInfo) {
        return result.file.readAsBytesSync();
      }
    }

    return null;
  }

  void _notify() {
    scaffoldMessengerKey.currentState!.showSnackBar(
      const SnackBar(
        content: Text("Download completed!"),
        backgroundColor: Colors.deepPurple,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(StringProperty("queue", queue.join(", ")));
  }
}
