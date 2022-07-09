import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import 'package:downsta/helpers/helpers.dart';
import 'package:downsta/services/services.dart';

final windowSharedDataRegex = RegExp(r"window\._sharedData = (.*);</script>");

const defaultHeaders = {
  HttpHeaders.acceptEncodingHeader: "gzip, deflate",
  HttpHeaders.acceptLanguageHeader: "en-US,en;q=0.8",
  "X-IG-APP-ID": "936619743392459",
};

abstract class ApiUrls {
  static const csrfToken = "/accounts/login";
  static const login = "/accounts/login/ajax/";
  static const loginCheck = "/accounts/login/";
  // TODO: data={"user_id": <user-id>} desktop
  static const logout = "/accounts/logout/ajax/";

  static const userInfo = "/api/v1/users/web_profile_info/";
  static const userInfo2 = "/api/v1/users/{USERID}/info/";
  static const following = "/api/v1/friendships/{USERID}/following/";

  static const reels = "/api/v1/clips/user/";
  static const videoInfo = "/api/v1/media/{ID}/info/";

  static const search = "/web/search/topsearch/";
  static const recentSearches = "/web/search/recent_searches/";
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
  static const stories = "303a4ae99711322310f25250d988f3b7";
  static const videos = "bc78b344a68ed16dd5d7f264681c4c76";
  static const postInfo = "2b0673e0dc4580674a88d426fe00ea90";
  static const highlights = "7c16654f22c819fb63d1183034a5162f";
  static const highlightItems = "45246d3fe16ccc6577e0bd297a5db1ab";
}

class Cache with DiagnosticableTreeMixin {
  Map<String, dynamic>? following;
  Map<String, dynamic> userInfo = {};
  Map<String, dynamic> videos = {};
  Map<String, dynamic> postsInfo = {};
  Map<String, dynamic> reels = {};
  Map<String, dynamic> search = {};
  Map<String, dynamic> stories = {};
  Map<String, dynamic> highlights = {};
  Map<String, dynamic> highlightItems = {};

  void resetCache() {
    following = null;
    userInfo = {};
    reels = {};
    search = {};
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
    await switchUser(username);
    await cookieJar.saveCookies(uri, res.headers["set-cookie"]);

    return null;
  }

  Future<void> logout(String username, {bool makeRequest = true}) async {
    if (makeRequest) {
      var uri = Uri(
        scheme: "https",
        host: "www.instagram.com",
        path: ApiUrls.logout,
      );

      await client.post(
        uri,
        body: {"user_id": await getUserId(username)},
        headers: {
          ...defaultHeaders,
          HttpHeaders.userAgentHeader: ApiUserAgents.desktop,
          HttpHeaders.cookieHeader: await cookieJar.getCookiesForHeader(uri),
          "X-CSRFToken": _csrfToken,
        },
      );
    }

    await cookieJar.deleteCookies(username);
    var loggedInUsers = await db.removeLoggedInUser(username);
    if (loggedInUsers.isNotEmpty) {
      await switchUser(loggedInUsers.first);
    }
  }

  Future<Map<String, dynamic>> getUserInfo(String username,
      {bool force = false}) async {
    var userInfo = cache.userInfo;
    if (!force && userInfo[username] != null) {
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

  Future<Map<String, dynamic>> getVideoInfo(String id,
      {bool force = false}) async {
    var postsInfo = cache.postsInfo;
    if (!force && postsInfo[id] != null) {
      return postsInfo[id];
    }

    var res = await getMobileJson(ApiUrls.videoInfo.replaceAll("{ID}", id));
    postsInfo[id] = res["items"].first;

    notifyListeners();

    return res;
  }

  Future<Map<String, dynamic>?> getPostInfo(String shortCode,
      {bool force = false}) async {
    var postsInfo = cache.postsInfo;
    if (!force && postsInfo[shortCode] != null) {
      return postsInfo[shortCode];
    }

    var res = await getGQLJson(
      ApiQueryHashes.postInfo,
      {"shortcode": shortCode},
    );
    final info = res["data"]["shortcode_media"];
    postsInfo[shortCode] = info;

    notifyListeners();

    return info;
  }

  Future<String> getProfilePicUrl(String username, {bool force = false}) async {
    var userInfo = cache.userInfo;
    if (!force && userInfo[username]["hd_profile_pic_url_info"] != null) {
      return userInfo[username]["hd_profile_pic_url_info"]["url"];
    }

    var res = await getMobileJson(
      ApiUrls.userInfo2.replaceAll("{USERID}", userInfo[username]["id"]),
    );
    var info = res["user"];
    userInfo[username].addAll(info);

    return info["hd_profile_pic_url_info"]["url"];
  }

  Future<String> getUserId(
    String username, {
    bool force = false,
  }) async {
    var userInfo = cache.userInfo;
    if (!force && userInfo[username] != null) {
      return userInfo[username]["id"];
    }

    var info = await getUserInfo(
      username,
      force: force,
    );
    return info["id"];
  }

  Future<Map<String, dynamic>> getReels(String username,
      {String endCursor = "", bool force = false}) async {
    var reels = cache.reels;
    if (endCursor == "" && !force && reels[username] != null) {
      return reels[username];
    }

    var res = await postMobileJson(
      ApiUrls.reels,
      body: {
        "target_user_id": await getUserId(username),
        "page_size": "12",
        "max_id": endCursor,
        "include_feed_video": "false",
      },
    );
    if (reels[username] != null) {
      reels[username]["items"].addAll(res["items"]);
      reels[username]["paging_info"] = res["paging_info"];
    } else {
      reels[username] = res;
    }

    notifyListeners();

    return res;
  }

  Future<Map<String, dynamic>> getSearchRes(String query,
      {bool force = false}) async {
    var search = cache.search;
    if (!force && search[query] != null) {
      return search[query];
    }

    Map<String, dynamic> res;
    if (query == "--recent-searches--") {
      res = await getJson(ApiUrls.recentSearches);
      res = {"users": res["recent"]};
      search[query] = res;
    } else {
      res = await getJson(
        ApiUrls.search,
        queryParameters: {"query": query},
      );
      search[query] = res;
    }

    notifyListeners();

    return res;
  }

  Future<Map<String, dynamic>> getStories(String username,
      {bool force = false}) async {
    var stories = cache.stories;
    if (!force && stories[username] != null) {
      return stories[username];
    }

    final id = await getUserId(username);
    final res = await getGQLJson(ApiQueryHashes.stories, {
      "reel_ids": [id],
      "precomposed_overlay": false,
    });
    final reelsMedia = res["data"]["reels_media"];
    Map<String, dynamic> data = reelsMedia.isEmpty ? {} : reelsMedia[0];
    stories[username] = data;

    notifyListeners();

    return data;
  }

  Future<List<dynamic>> getHighlights(String username,
      {bool force = false}) async {
    var highlights = cache.highlights;
    if (!force && highlights[username] != null) {
      return highlights[username];
    }

    var res = await getGQLJson(
      ApiQueryHashes.highlights,
      {
        "user_id": await getUserId(username),
        "include_chaining": false,
        "include_reel": false,
        "include_suggested_users": false,
        "include_logged_out_extras": false,
        "include_highlight_reels": true
      },
    );
    final edges = res["data"]["user"]["edge_highlight_reels"]["edges"];
    highlights[username] = edges;

    notifyListeners();

    return edges;
  }

  Future<Map<String, dynamic>> getHighlightItems(String highlightId,
      {bool force = false}) async {
    var highlightItems = cache.highlightItems;
    if (!force && highlightItems[highlightId] != null) {
      return highlightItems[highlightId];
    }

    var res = await getGQLJson(
      ApiQueryHashes.highlightItems,
      {
        "reel_ids": [],
        "tag_names": [],
        "location_ids": [],
        "highlight_reel_ids": [highlightId],
        "precomposed_overlay": false
      },
    );
    final reelsMedia = res["data"]["reels_media"][0];
    highlightItems[highlightId] = reelsMedia;

    notifyListeners();

    return reelsMedia;
  }

  Future<Map<String, dynamic>> get(
      {required String queryHash,
      required Map<String, dynamic> params,
      required Map<String, dynamic> Function(Map<String, dynamic>) resExtractor,
      required Map<String, dynamic>? Function(Cache) cacheExtractor,
      bool initial = false,
      void Function(Cache)? cacheInitializer,
      bool force = false,
      String referer = "https://www.instagram.com/"}) async {
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

    var res = await getGQLJson(
      queryHash,
      {"first": 25, ...params},
      referer: referer,
    );
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

  Future<dynamic> postJson(String path,
      {String host = "www.instagram.com", Map<String, dynamic>? body}) async {
    var uri = Uri(
      scheme: "https",
      host: host,
      path: path,
    );

    var res = await client.post(
      uri,
      headers: {
        ...defaultHeaders,
        HttpHeaders.userAgentHeader: ApiUserAgents.getUserAgentByHost(host),
        HttpHeaders.cookieHeader: await cookieJar.getCookiesForHeader(uri),
        "X-CSRFToken": _csrfToken,
      },
      body: body,
    );

    // TODO: Figure out whether we need to save the cookies here or not
    // cookieJar.saveCookies(uri, res.headers["set-cookie"]);

    return jsonDecode(res.body);
  }

  Future<dynamic> getMobileJson(String path,
      {Map<String, dynamic>? queryParameters}) {
    return getJson(path,
        host: "i.instagram.com", queryParameters: queryParameters);
  }

  Future<dynamic> postMobileJson(String path, {Map<String, dynamic>? body}) {
    return postJson(path, host: "i.instagram.com", body: body);
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
    String referer = "www.instagram.com",
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
      HttpHeaders.refererHeader: referer,
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
