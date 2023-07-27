import 'dart:io';

import 'package:path_provider/path_provider.dart';

String getCacheKey(String url) {
  var uri = Uri.parse(url);
  return uri.queryParameters["ig_cache_key"] ?? url;
}

Future<String> getAppDataStorageDir() async {
  Directory dir;
  if (Platform.isAndroid) {
    dir = (await getExternalStorageDirectory())!;
  } else {
    dir = await getApplicationSupportDirectory();
  }

  return dir.path;
}

Future<String> getDownloadsDir() async {
  // `getDownloadsDirectory` is not available on Android, so hardcode it!
  if (Platform.isAndroid) {
    return "/storage/emulated/0";
  }

  return (await getDownloadsDirectory())!.path;
}
