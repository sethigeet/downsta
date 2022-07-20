import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import 'package:downsta/models/models.dart';
import 'package:downsta/services/services.dart';
import 'package:downsta/helpers/helpers.dart';

final windowSharedDataRegex = RegExp(r"window\._sharedData = (.*);</script>");

const defaultHeaders = {
  HttpHeaders.acceptEncodingHeader: "gzip, deflate",
  HttpHeaders.acceptLanguageHeader: "en-US,en;q=0.8",
  "X-IG-APP-ID": "936619743392459",
};

const acceptedPostTypes = ["GraphImage", "GraphVideo", "GraphSidecar"];

abstract class ApiUrls {
  static const csrfToken = "/accounts/login";
  static const login = "/accounts/login/ajax/";
  static const loginCheck = "/accounts/login/";
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
  static const feed = "d6f4427fbe92d846298cf93df0b937d3";
  static const following = "58712303d941c6855d4e888c5f0cd22f";
  static const posts = "003056d32c2554def87228bc3fd9668a";
  static const stories = "303a4ae99711322310f25250d988f3b7";
  static const videos = "bc78b344a68ed16dd5d7f264681c4c76";
  static const postInfo = "2b0673e0dc4580674a88d426fe00ea90";
  static const highlights = "7c16654f22c819fb63d1183034a5162f";
  static const highlightItems = "45246d3fe16ccc6577e0bd297a5db1ab";
}

class Cache with DiagnosticableTreeMixin {
  PaginatedResponse<Post>? feed;
  PaginatedResponse<Profile>? following;
  Map<String, Profile> profiles = {};
  Map<String, PaginatedResponse<Post>> videos = {};
  Map<String, Video> postsInfo = {};
  Map<String, PaginatedResponse<Reel>> reels = {};
  Map<String, dynamic> search = {};
  Map<String, List<Story>> stories = {};
  Map<String, dynamic> highlights = {};
  Map<String, List<Story>> highlightItems = {};

  void resetCache() {
    feed = null;
    following = null;
    profiles = {};
    videos = {};
    postsInfo = {};
    reels = {};
    search = {};
    stories = {};
    highlights = {};
    highlightItems = {};
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(StringProperty("feed", following.toString()));
    properties.add(StringProperty("following", following.toString()));
    properties.add(StringProperty("profiles", profiles.toString()));
    properties.add(StringProperty("videos", videos.toString()));
    properties.add(StringProperty("postsInfo", postsInfo.toString()));
    properties.add(StringProperty("reels", reels.toString()));
    properties.add(StringProperty("search", search.toString()));
    properties.add(StringProperty("stories", stories.toString()));
    properties.add(StringProperty("highlights", highlights.toString()));
    properties.add(StringProperty("highlightItems", highlightItems.toString()));
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

  Future<Profile> getUserInfo(String username, {bool force = false}) async {
    var userInfo = cache.profiles;
    if (!force && userInfo[username] != null) {
      return userInfo[username]!;
    }

    var res = await getMobileJson(
      ApiUrls.userInfo,
      queryParameters: {"username": username},
    );
    var profile = Profile(res["data"]["user"]);
    userInfo[username] = profile;

    notifyListeners();

    return profile;
  }

  Future<Video> getVideoInfo(String id, {bool force = false}) async {
    var videosInfo = cache.postsInfo;
    if (!force && videosInfo[id] != null) {
      return videosInfo[id]!;
    }

    var res = await getMobileJson(ApiUrls.videoInfo.replaceAll("{ID}", id));
    final video = Video(res["items"].first);
    videosInfo[id] = video;

    notifyListeners();

    return video;
  }

  Future<Post?> getPostInfo(String shortCode, {bool force = false}) async {
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
    var profile = cache.profiles[username]!;
    if (!force && profile.hdProfilePicAvailable) {
      return profile.profilePicUrlHd;
    }

    var res = await getMobileJson(
      ApiUrls.userInfo2.replaceAll("{USERID}", profile.id),
    );
    var info = res["user"];
    profile.update(info);

    return profile.profilePicUrlHd;
  }

  Future<String> getUserId(
    String username, {
    bool force = false,
  }) async {
    var profile = cache.profiles[username];
    if (!force && profile != null) {
      return profile.id;
    }

    var info = await getUserInfo(
      username,
      force: force,
    );
    return info.id;
  }

  Future<PaginatedResponse<Reel>> getReels(String username,
      {String endCursor = "", bool force = false}) async {
    var reels = cache.reels;
    if (endCursor == "" && !force && reels[username] != null) {
      return reels[username]!;
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

    var reel = reels[username];
    if (reel != null) {
      reel.addEdges(
          List<Reel>.from(res["items"].map((item) => Reel(item["media"]))));
      var pagingInfo = res["paging_info"];
      reel.updatePageInfo({
        "has_next_page": pagingInfo["more_available"],
        "end_cursor": pagingInfo["max_id"],
      });
    } else {
      var temp = PaginatedResponse<Reel>.empty();
      temp.addEdges(
          List<Reel>.from(res["items"].map((item) => Reel(item["media"]))));
      var pagingInfo = res["paging_info"];
      temp.updatePageInfo({
        "has_next_page": pagingInfo["more_available"],
        "end_cursor": pagingInfo["max_id"],
      });

      reels[username] = temp;
    }

    notifyListeners();

    return reels[username]!;
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

  Future<List<Story>> getStories(String username, {bool force = false}) async {
    var stories = cache.stories;
    if (!force && stories[username] != null) {
      return stories[username]!;
    }

    final id = await getUserId(username);
    final res = await getGQLJson(ApiQueryHashes.stories, {
      "reel_ids": [id],
      "precomposed_overlay": false,
    });
    final reelsMedia = res["data"]["reels_media"];
    List<Story> data = reelsMedia.isEmpty
        ? []
        : List<Story>.from(reelsMedia[0]["items"].map((node) => Story(node)));
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

  Future<List<Story>> getHighlightItems(String highlightId,
      {bool force = false}) async {
    var highlightItems = cache.highlightItems;
    if (!force && highlightItems[highlightId] != null) {
      return highlightItems[highlightId]!;
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
    List<Story> items =
        List<Story>.from(reelsMedia["items"].map((node) => Story(node)));
    highlightItems[highlightId] = items;

    notifyListeners();

    return items;
  }

  Future<PaginatedResponse<T>> get<T>(
      {required String queryHash,
      required Map<String, dynamic> params,
      required Map<String, dynamic> Function(Map<String, dynamic>) resExtractor,
      required PaginatedResponse<T>? Function(Cache) cacheExtractor,
      required T? Function(Map<String, dynamic>) nodeConverter,
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
      return get<T>(
        queryHash: queryHash,
        params: params,
        resExtractor: resExtractor,
        nodeConverter: nodeConverter,
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
    oldData.updatePageInfo(newData["page_info"]);
    oldData.addEdges(List<T>.from((newData["edges"] as List)
        .map((edge) => nodeConverter(edge["node"]))
        .where((node) => node != null)));

    notifyListeners();

    return oldData;
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
