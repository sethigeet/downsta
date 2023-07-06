import 'package:drift/drift.dart';
import 'package:cookie_jar/cookie_jar.dart';

import 'package:downsta/services/db.dart' show DB, CookiesCompanion;

final cookieSplitRegex = RegExp(r',(?=[^ ])');

class DBStorage implements Storage {
  final DB db;
  final String username;

  DBStorage(this.db, this.username);

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) =>
      db.createCookie(username);

  @override
  Future<void> delete(String key) async {
    var changes = const CookiesCompanion();
    switch (key) {
      case ".index":
        changes = const CookiesCompanion(index: Value(""));
        break;
      case ".domains":
        changes = const CookiesCompanion(domains: Value(""));
        break;
    }

    db.updateCookie(username, changes);
  }

  @override
  Future<void> deleteAll(List<String> keys) => db.deleteCookie(username);

  @override
  Future<String?> read(String key) async {
    var cookie = await db.getCookie(username);
    if (cookie == null) {
      return null;
    }

    switch (key) {
      case ".index":
        return cookie.index;
      case ".domains":
        return cookie.domains;
    }

    return null;
  }

  @override
  Future<void> write(String key, String value) async {
    var changes = const CookiesCompanion();
    switch (key) {
      case ".index":
        changes = CookiesCompanion(index: Value(value));
        break;
      case ".domains":
        changes = CookiesCompanion(domains: Value(value));
        break;
    }

    db.updateCookie(username, changes);
  }
}

class CookieJar {
  late PersistCookieJar _jar;

  CookieJar(DB db, String username) {
    _jar = PersistCookieJar(storage: DBStorage(db, username));
  }

  static Future<CookieJar> getNewCookieJar(DB db, String username) async {
    return CookieJar(db, username);
  }

  Future<List<Cookie>> getCookies(Uri uri) => _jar.loadForRequest(uri);

  static String getCookiesStringForHeaderFromCookies(List<Cookie> cookies) =>
      cookies.map((cookie) => cookie.toString()).join("; ");

  Future<String> getCookiesForHeader(Uri uri) async {
    var cookies = await getCookies(uri);
    return cookies.map((cookie) => cookie.toString()).join("; ");
  }

  Future<void> saveCookies(Uri uri, String? cookieHeader) async {
    if (cookieHeader == null || cookieHeader.isEmpty) {
      return;
    }

    final cookies = cookieHeader.split(cookieSplitRegex);
    if (cookies.isEmpty) {
      return;
    }

    final parsedCookies = List<Cookie>.from(cookies.map((c) {
      try {
        return Cookie.fromSetCookieValue(c);
      } catch (_) {
        return null;
      }
    }).where((c) => c != null));
    await _jar.saveFromResponse(
        Uri(scheme: "https", host: "i.instagram.com"), parsedCookies);
    await _jar.saveFromResponse(
        Uri(scheme: "https", host: "www.instagram.com"), parsedCookies);
  }

  Future<void> deleteCookies(String username) async {
    try {
      await _jar.deleteAll();
    } catch (_) {}
  }
}
