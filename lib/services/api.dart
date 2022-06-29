import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import 'package:downsta/helpers/cookie_jar.dart';
import 'package:downsta/services/db.dart';

final windowSharedDataRegex = RegExp(r"window\._sharedData = (.*);</script>");

const defaultHeaders = {
  HttpHeaders.acceptEncodingHeader: "gzip, deflate",
  HttpHeaders.acceptLanguageHeader: "en-US,en;q=0.8",
  HttpHeaders.refererHeader: "https://www.instagram.com/",
};

abstract class ApiUrls {
  static const csrfToken = "/accounts/login";
  static const login = "/accounts/login/ajax/";
  static const loginCheck = "/accounts/login/";
  // TODO: data={"user_id": <user-id>} desktop
  static const logout = "/accounts/logout/ajax/";

  static const userInfo = "/api/v1/users/web_profile_info/";
  static const following = "/api/v1/friendships/{USERID}/following/";

  // TODO: data={"target_user_id": "<userid>"} mobile
  static const reels = "/api/v1/clips/user/";
  // TODO: mobile
  static const stories = "/api/v1/feed/user/{USERID}/story/";

  // TODO: params={"query": SEARCH_TERM} desktop
  static const search = "/web/search/topsearch/";
}

abstract class ApiUserAgents {
  static const desktop =
      "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.131 Safari/537.36";
  static const mobile =
      "Instagram 146.0.0.27.125 (iPhone12,1; iOS 13_3; en_US; en-US; scale=2.00; 1656x3584; 190542906)";

  static String getUserAgentByHost(String host) {
    if (host.contains("www")) {
      return ApiUserAgents.desktop;
    }

    return ApiUserAgents.mobile;
  }
}

abstract class ApiQueryHashes {
  static const following = "58712303d941c6855d4e888c5f0cd22f";
  static const posts = "003056d32c2554def87228bc3fd9668a";
}

class Cache with DiagnosticableTreeMixin {
  Map<String, dynamic>? following;
  Map<String, dynamic> userInfo = {};

  void resetCache() {
    following = null;
    userInfo = {};
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(StringProperty("userInfo", userInfo.toString()));
    properties.add(StringProperty("following", following.toString()));
  }
}

class Api with ChangeNotifier, DiagnosticableTreeMixin {
  final http.Client client = http.Client();
  final DB db;
  CookieJar cookieJar;
  String _csrfToken;

  final Cache cache = Cache();
  bool? isLoggedIn;

  String username;

  Api(this.username, this.cookieJar, this.db, this._csrfToken);

  static Future<Api> create(String username, DB db) async {
    final cookies = await CookieJar.getNewCookieJar(username);
    return Api(username, cookies, db, "");
  }

  Future<bool> getIsLoggedIn() async {
    if (isLoggedIn != null) {
      return isLoggedIn!;
    }

    var uri = Uri(
      scheme: "https",
      host: "www.instagram.com",
      path: ApiUrls.loginCheck,
    );

    var cookies = await cookieJar.getCookies(uri);
    if (cookies.isEmpty) {
      isLoggedIn = false;
      return false;
    }

    try {
      final sessIdCookie =
          cookies.firstWhere((cookie) => cookie.name == "sessionid");
      if (sessIdCookie.value.isEmpty) {
        isLoggedIn = false;
        return false;
      }
    } catch (_) {
      isLoggedIn = false;
      return false;
    }

    try {
      _csrfToken =
          cookies.firstWhere((cookie) => cookie.name == "csrftoken").value;
    } catch (_) {
      isLoggedIn = false;
      return false;
    }
    var req = http.Request("GET", uri);
    req.followRedirects = false;
    req.headers.addAll({
      ...defaultHeaders,
      HttpHeaders.userAgentHeader: ApiUserAgents.desktop,
      HttpHeaders.cookieHeader:
          CookieJar.getCookiesStringForHeaderFromCookies(cookies),
      "X-CSRFToken": _csrfToken,
    });
    var res = await client.send(req);
    if (!res.isRedirect) {
      isLoggedIn = false;
      return false;
    }

    isLoggedIn = true;
    return true;
  }

  Future<void> switchUser(String username) async {
    this.username = username;
    cookieJar = await CookieJar.getNewCookieJar(username);
    cache.resetCache();

    await db.setLastLoggedInUser(username);

    notifyListeners();
  }

  Future<String?> login(String username, String password) async {
    isLoggedIn = null;

    final csrfRes = await getWindowSharedData(
      ApiUrls.csrfToken,
      sendCookies: false,
    );
    _csrfToken = csrfRes["config"]["csrf_token"];

    sleep(const Duration(seconds: 1));

    final encPassword =
        '#PWD_INSTAGRAM_BROWSER:0:${DateTime.now().millisecondsSinceEpoch}:$password';
    final uri = Uri(
      scheme: "https",
      host: "www.instagram.com",
      path: ApiUrls.login,
    );
    final res = await client.post(
      uri,
      headers: {
        ...defaultHeaders,
        HttpHeaders.userAgentHeader: ApiUserAgents.desktop,
        "X-CSRFToken": _csrfToken,
      },
      body: {
        "username": username,
        "enc_password": encPassword,
      },
      encoding: Encoding.getByName("json"),
    );

    final resJson = jsonDecode(res.body);

    if (resJson["status"] != "ok") {
      return "status: ${resJson["status"]}, message: ${resJson["message"]}";
    }

    if (resJson["authenticated"] == null) {
      return "Unexpected response, message: ${resJson["message"]}";
    }

    if (resJson["authenticated"] != true) {
      if (resJson["user"] != null) {
        return "Wrong password";
      } else {
        return "User $username does not exist";
      }
    }

    isLoggedIn = true;
    cookieJar.saveCookies(uri, res.headers["set-cookie"]);
    await switchUser(username);

    return null;
  }

  Future<Map<String, dynamic>> getUserInfo(String username,
      {bool? force}) async {
    var userInfo = cache.userInfo;
    if ((force == null || !force) && userInfo[username] != null) {
      return userInfo[username];
    }

    var res = await getMobileJson(
      ApiUrls.userInfo,
      queryParameters: {"username": username},
    );
    var info = res["data"]["user"];
    userInfo[username] = info;

    notifyListeners();

    return info;
  }

  Future<String> getUserId(
    String username, {
    bool? force,
  }) async {
    var userInfo = cache.userInfo;
    if ((force == null || !force) && userInfo[username] != null) {
      return userInfo[username]["id"];
    }

    var info = await getUserInfo(
      username,
      force: force,
    );
    return info["id"];
  }

  Future<Map<String, dynamic>> get({
    required String queryHash,
    required Map<String, dynamic> params,
    required Map<String, dynamic> Function(Map<String, dynamic>) resExtractor,
    required Map<String, dynamic>? Function(Cache) cacheExtractor,
    bool initial = false,
    void Function(Cache)? cacheInitializer,
    bool force = false,
  }) async {
    if (initial) {
      var oldData = cacheExtractor(cache);
      if (!force && oldData != null) {
        return oldData;
      }

      if (cacheInitializer == null) {
        throw ErrorHint(
            "cacheInitializer cannot be null if this is the initial request and there is no cached data available!");
      }
      return get(
        queryHash: queryHash,
        params: params,
        resExtractor: resExtractor,
        cacheExtractor: (cache) {
          cacheInitializer(cache);
          return cacheExtractor(cache);
        },
      );
    }

    var res = await getGQLJson(queryHash, {"first": 25, ...params});
    var newData = resExtractor(res["data"]);
    var oldData = cacheExtractor(cache);
    if (oldData == null) {
      throw ErrorHint(
          "cached data cannot be null if this is not the initial request");
    }
    oldData["page_info"] = newData["page_info"];
    oldData["edges"].addAll(newData["edges"]);

    notifyListeners();

    return newData;
  }

  Future<dynamic> getJson(String path,
      {String host = "www.instagram.com",
      Map<String, dynamic>? queryParameters}) async {
    var uri = Uri(
        scheme: "https",
        host: host,
        path: path,
        queryParameters: queryParameters);

    var res = await client.get(uri, headers: {
      ...defaultHeaders,
      HttpHeaders.userAgentHeader: ApiUserAgents.getUserAgentByHost(host),
      HttpHeaders.cookieHeader: await cookieJar.getCookiesForHeader(uri),
      "X-CSRFToken": _csrfToken,
    });

    // TODO: Figure out whether we need to save the cookies here or not
    // cookieJar.saveCookies(uri, res.headers["set-cookie"]);

    return jsonDecode(res.body);
  }

  Future<dynamic> getMobileJson(String path,
      {Map<String, dynamic>? queryParameters}) {
    return getJson(path,
        host: "i.instagram.com", queryParameters: queryParameters);
  }

  Future<dynamic> getWindowSharedData(String path,
      {String host = "www.instagram.com",
      Map<String, dynamic>? queryParameters,
      bool? sendCookies}) async {
    var uri = Uri(
        scheme: "https",
        host: host,
        path: path,
        queryParameters: queryParameters);

    var res = await client.get(uri, headers: {
      ...defaultHeaders,
      HttpHeaders.userAgentHeader: ApiUserAgents.getUserAgentByHost(host),
      HttpHeaders.cookieHeader: sendCookies != null && sendCookies
          ? await cookieJar.getCookiesForHeader(uri)
          : "",
      // "X-CSRFToken": _csrfToken,
    });

    final match = windowSharedDataRegex.firstMatch(res.body);
    if (match == null) {
      return null;
    }

    return jsonDecode(match.group(1)!);
  }

  Future<dynamic> getGQLJson(
    String queryHash,
    Map<String, dynamic> variables, {
    String host = "www.instagram.com",
  }) async {
    var uri = Uri(
        scheme: "https",
        host: host,
        path: "graphql/query",
        queryParameters: {
          "query_hash": queryHash,
          "variables": jsonEncode(variables)
        });

    var res = await client.get(uri, headers: {
      ...defaultHeaders,
      HttpHeaders.acceptHeader: "*/*",
      HttpHeaders.userAgentHeader: ApiUserAgents.getUserAgentByHost(host),
      HttpHeaders.cookieHeader: await cookieJar.getCookiesForHeader(uri),
      "X-CSRFToken": _csrfToken,
    });

    // TODO: Figure out whether we need to save the cookies here or not
    // cookieJar.saveCookies(uri, res.headers["set-cookie"]);

    return jsonDecode(res.body);
  }
}
