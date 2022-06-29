import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';

import 'package:downsta/utils.dart';

final cookieSplitRegex = RegExp(r',(?=[^ ])');

class CookieJar {
  late PersistCookieJar _jar;

  CookieJar(String filename) {
    _jar = PersistCookieJar(storage: FileStorage(filename));
  }

  static Future<CookieJar> getNewCookieJar(String username) async {
    final dir = await getAppDataStorageDir();
    return CookieJar("$dir/session-cookies-$username");
  }

  Future<List<Cookie>> getCookies(Uri uri) => _jar.loadForRequest(uri);

  static String getCookiesStringForHeaderFromCookies(List<Cookie> cookies) =>
      cookies.map((cookie) => cookie.toString()).join("; ");

  Future<String> getCookiesForHeader(Uri uri) async {
    var cookies = await getCookies(uri);
    return cookies.map((cookie) => cookie.toString()).join("; ");
  }

  void saveCookies(Uri uri, String? cookieHeader) async {
    if (cookieHeader == null || cookieHeader.isEmpty) {
      return;
    }

    final cookies = cookieHeader.split(cookieSplitRegex);
    if (cookies.isEmpty) {
      return;
    }

    final parsedCookies =
        cookies.map((c) => Cookie.fromSetCookieValue(c)).toList();
    await _jar.saveFromResponse(
        Uri(scheme: "https", host: "i.instagram.com"), parsedCookies);
    await _jar.saveFromResponse(
        Uri(scheme: "https", host: "www.instagram.com"), parsedCookies);
  }
}
