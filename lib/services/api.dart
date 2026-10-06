import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import 'package:downsta/models/models.dart';
import 'package:downsta/services/services.dart';
import 'package:downsta/helpers/helpers.dart';

final windowSharedDataRegex = RegExp(r"window\._sharedData = (.*);</script>");
final csrfTokenRegex = RegExp(
  r'\["XIGSharedData", \[\], \{"raw": "\{\\"config\\":\{\\"csrf_token\\":\\"(.*)\\",\\"viewer',
);
final userIdRegex = RegExp(r'"profile_id":"(\d+)"');
final dtsgRegex = RegExp(r'\["DTSGInitData",\[\],{"token":"([^"]+)",');
final lsdRegex = RegExp(r'"LSD",\[\],\{"token":"([^"]+)"\}');
final apcRegex = RegExp(r'[?&]apc=([^&"]+)');

const defaultHeaders = {
  HttpHeaders.acceptEncodingHeader: "gzip, deflate",
  HttpHeaders.acceptLanguageHeader: "en-US,en;q=0.8",
  "X-IG-APP-ID": "936619743392459",
  "sec-fetch-site": "same-origin",
  "X-BLOKS-VERSION-ID":
      "6a1a99aad521621204ad31915fc0c45ea5ef62c4d409c123a63ab00c26644d3c",
};

const acceptedPostTypes = ["GraphImage", "GraphVideo", "GraphSidecar"];

class ChallengeInfo {
  final String apiPath;
  final String? phoneNumber;
  final String? email;

  ChallengeInfo({required this.apiPath, this.phoneNumber, this.email});
}

class LoginResult {
  final bool success;
  final String? error;
  final ChallengeInfo? challengeInfo;

  LoginResult({required this.success, this.error, this.challengeInfo});

  bool get requiresChallenge => challengeInfo != null;
}

abstract class ApiUrls {
  static const csrfToken = "/accounts/login";
  static const login = "/accounts/login/ajax/";
  static const loginCheck = "/accounts/login/";
  static const logout = "/accounts/logout/ajax/";
  static const challengeReplay = "/challenge/replay/";

  static const userInfo = "/api/v1/users/web_profile_info/";
  static const userInfo2 = "/api/v1/users/{USERID}/info/";
  static const following = "/api/v1/friendships/{USERID}/following/";

  static const posts = "api/v1/feed/user/{USERNAME}/username/";
  static const reels = "/api/v1/clips/user/";
  static const videoInfo = "/api/v1/media/{ID}/info/";

  static const search = "/web/search/topsearch/";
  static const recentSearches = "/web/search/recent_searches/";
}

abstract class ApiUserAgents {
  static const desktop =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36";
  static const mobile =
      "Instagram 361.0.0.35.82 (iPad13,8; iOS 18_0; en_US; en-US; scale=2.00; 2048x2732; 674117118) AppleWebKit/420";

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

abstract class ApiDocIds {
  static const posts = "26558563207156056";
  static const reels = "7845543455542541";
  static const userInfo = "26672929172408668";
}

class Cache with DiagnosticableTreeMixin {
  PaginatedResponse<Post>? feed;
  PaginatedResponse<Profile>? following;
  Map<String, Profile> profiles = {};
  Map<String, PaginatedResponse<Post>> videos = {};
  Map<String, Video> postsInfo = {};
  Map<String, PaginatedResponse<Reel>> reels = {};
  Map<String, List<Profile>> search = {};
  Map<String, List<Story>> stories = {};
  Map<String, List<Highlight>> highlights = {};
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
  String? _dtsg;

  final Cache cache = Cache();
  bool? isLoggedIn;

  String username;

  Api(this.username, this.cookieJar, this.db, this._csrfToken);

  static Future<Api> create(String username, DB db) async {
    final cookies = await CookieJar.getNewCookieJar(db, username);
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
      final sessIdCookie = cookies.firstWhere(
        (cookie) => cookie.name == "sessionid",
      );
      if (sessIdCookie.value.isEmpty) {
        isLoggedIn = false;
        return false;
      }
    } catch (_) {
      isLoggedIn = false;
      return false;
    }

    try {
      _csrfToken = await getCsrfTokenNew(sendCookies: false);
    } catch (_) {
      isLoggedIn = false;
      return false;
    }

    // var req = http.Request("GET", uri);
    // req.followRedirects = false;
    // req.headers.addAll({
    //   ...defaultHeaders,
    //   HttpHeaders.userAgentHeader: ApiUserAgents.desktop,
    //   HttpHeaders.cookieHeader: CookieJar.getCookiesStringForHeaderFromCookies(
    //     cookies,
    //   ),
    //   "X-CSRFToken": _csrfToken,
    // });
    // var res = await client.send(req);
    // if (res.isRedirect) {
    //   isLoggedIn = false;
    //   return false;
    // }

    isLoggedIn = true;
    return true;
  }

  Future<void> switchUser(String username) async {
    this.username = username;
    cookieJar = await CookieJar.getNewCookieJar(db, username);
    cache.resetCache();

    await db.setLastLoggedInUser(username);

    notifyListeners();
  }

  String? _pendingChallengeUsername;
  String? _pendingChallengeApiPath;
  String? _encryptedApContext;
  String? _lsdToken;
  int _clientMutationId = 0;

  Future<LoginResult> login(String username, String password) async {
    isLoggedIn = null;
    _clientMutationId = 0;

    _csrfToken = await getCsrfTokenNew(sendCookies: false);

    // Sleep to avoid rate limiting
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
      body: {"username": username, "enc_password": encPassword},
      encoding: Encoding.getByName("json"),
    );

    await cookieJar.saveCookies(uri, res.headers["set-cookie"]);

    final resJson = jsonDecode(res.body);

    // Check for challenge required
    if (resJson["message"] == "checkpoint_required" ||
        resJson["checkpoint_url"] != null) {
      final checkpointUrl = resJson["checkpoint_url"] as String?;
      if (checkpointUrl != null) {
        _pendingChallengeUsername = username;
        _pendingChallengeApiPath = checkpointUrl;

        // Initialize the challenge to get encrypted context
        final initResult = await _initChallenge();
        if (!initResult.success) {
          return initResult;
        }

        return LoginResult(
          success: false,
          challengeInfo: ChallengeInfo(apiPath: checkpointUrl),
        );
      }
    }

    if (resJson["status"] != "ok") {
      return LoginResult(
        success: false,
        error: "status: ${resJson["status"]}, message: ${resJson["message"]}",
      );
    }

    if (resJson["authenticated"] == null) {
      return LoginResult(
        success: false,
        error: "Unexpected response, message: ${resJson["message"]}",
      );
    }

    if (resJson["authenticated"] != true) {
      if (resJson["user"] != null) {
        return LoginResult(success: false, error: "Wrong password");
      } else {
        return LoginResult(
          success: false,
          error: "User $username does not exist",
        );
      }
    }

    isLoggedIn = true;
    await switchUser(username);

    return LoginResult(success: true);
  }

  Future<LoginResult> _initChallenge() async {
    if (_pendingChallengeApiPath == null) {
      return LoginResult(success: false, error: "No pending challenge");
    }

    // First, try to extract apc from the checkpoint URL itself
    final apcMatch = apcRegex.firstMatch(_pendingChallengeApiPath!);
    if (apcMatch != null) {
      _encryptedApContext = Uri.decodeComponent(apcMatch.group(1)!);
      debugPrint("Found APC in checkpoint URL");
    }

    // Fetch the challenge page to get LSD token and cookies
    final uri = Uri(
      scheme: "https",
      host: "www.instagram.com",
      path: _pendingChallengeApiPath,
    );

    final res = await client.get(
      uri,
      headers: {
        HttpHeaders.userAgentHeader: ApiUserAgents.desktop,
        HttpHeaders.cookieHeader: await cookieJar.getCookiesForHeader(uri),
        HttpHeaders.acceptHeader:
            "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
      },
    );

    await cookieJar.saveCookies(uri, res.headers["set-cookie"]);

    // Extract LSD token from the page
    final lsdMatch = lsdRegex.firstMatch(res.body);
    if (lsdMatch != null) {
      _lsdToken = lsdMatch.group(1);
    }

    debugPrint("Challenge init - LSD: $_lsdToken");
    debugPrint(
      "Challenge init - APC: ${_encryptedApContext != null ? "${_encryptedApContext!.substring(0, _encryptedApContext!.length > 50 ? 50 : _encryptedApContext!.length)}..." : "null"}",
    );

    if (_encryptedApContext == null) {
      return LoginResult(
        success: false,
        error:
            "Could not extract challenge context. Manual verification may be required.",
      );
    }

    // Make the AuthPlatformCodeEntryViewQuery request to trigger push notification to phone
    await _triggerPhoneApprovalNotification();

    return LoginResult(success: true);
  }

  Future<void> _triggerPhoneApprovalNotification() async {
    if (_encryptedApContext == null || _lsdToken == null) return;

    final uri = Uri(
      scheme: "https",
      host: "www.instagram.com",
      path: "/api/graphql",
    );

    final referer =
        "https://www.instagram.com/auth_platform/codeentry/?apc=${Uri.encodeComponent(_encryptedApContext!)}";

    // Request 1: AuthPlatformCodeEntryViewQuery
    final headers1 = {
      HttpHeaders.userAgentHeader: ApiUserAgents.desktop,
      HttpHeaders.cookieHeader: await cookieJar.getCookiesForHeader(uri),
      HttpHeaders.contentTypeHeader: "application/x-www-form-urlencoded",
      HttpHeaders.acceptHeader: "*/*",
      "x-csrftoken": _csrfToken,
      "x-ig-app-id": "936619743392459",
      "x-fb-lsd": _lsdToken ?? "",
      "sec-fetch-dest": "empty",
      "sec-fetch-mode": "cors",
      "sec-fetch-site": "same-origin",
    };
    headers1[HttpHeaders.refererHeader] = referer;
    headers1["x-fb-friendly-name"] = "AuthPlatformCodeEntryViewQuery";
    headers1["x-fb-lsd"] = _lsdToken!;

    final body1 = {
      "av": "0",
      "__d": "www",
      "__user": "0",
      "__a": "1",
      "__req": "1",
      "dpr": "1",
      "__ccg": "GOOD",
      "lsd": _lsdToken!,
      "fb_api_caller_class": "RelayModern",
      "fb_api_req_friendly_name": "AuthPlatformCodeEntryViewQuery",
      "variables": jsonEncode({"apc": _encryptedApContext}),
      "server_timestamps": "true",
      "doc_id": "34414353874878894",
    };

    try {
      final res1 = await client.post(uri, headers: headers1, body: body1);
      debugPrint("AuthPlatformCodeEntryViewQuery response: ${res1.statusCode}");
      await cookieJar.saveCookies(uri, res1.headers["set-cookie"]);
    } catch (e) {
      debugPrint("AuthPlatformCodeEntryViewQuery failed: $e");
    }

    // Request 2: ConversationalSupportIGLRRChatExperienceQuery
    final headers2 = {
      HttpHeaders.userAgentHeader: ApiUserAgents.desktop,
      HttpHeaders.cookieHeader: await cookieJar.getCookiesForHeader(uri),
      HttpHeaders.contentTypeHeader: "application/x-www-form-urlencoded",
      HttpHeaders.acceptHeader: "*/*",
      "x-csrftoken": _csrfToken,
      "x-ig-app-id": "936619743392459",
      "x-fb-lsd": _lsdToken ?? "",
      "sec-fetch-dest": "empty",
      "sec-fetch-mode": "cors",
      "sec-fetch-site": "same-origin",
    };
    headers2[HttpHeaders.refererHeader] = referer;
    headers2["x-fb-friendly-name"] =
        "ConversationalSupportIGLRRChatExperienceQuery";
    headers2["x-fb-lsd"] = _lsdToken!;

    final body2 = {
      "av": "0",
      "__d": "www",
      "__user": "0",
      "__a": "1",
      "__req": "5",
      "dpr": "1",
      "__ccg": "GOOD",
      "lsd": _lsdToken!,
      "fb_api_caller_class": "RelayModern",
      "fb_api_req_friendly_name":
          "ConversationalSupportIGLRRChatExperienceQuery",
      "variables": jsonEncode({
        "request": {"apc": _encryptedApContext, "existing_token": null},
      }),
      "server_timestamps": "true",
      "doc_id": "26125487770473479",
    };

    try {
      final res2 = await client.post(uri, headers: headers2, body: body2);
      debugPrint("ConversationalSupportQuery response: ${res2.statusCode}");
      await cookieJar.saveCookies(uri, res2.headers["set-cookie"]);
    } catch (e) {
      debugPrint("ConversationalSupportQuery failed: $e");
    }
  }

  Future<LoginResult> verifyLoginAfterApproval() async {
    if (_pendingChallengeUsername == null) {
      return LoginResult(success: false, error: "No pending challenge");
    }

    // Reset login state and check if we're now logged in
    isLoggedIn = null;

    final loggedIn = true;
    if (loggedIn) {
      await switchUser(_pendingChallengeUsername!);
      _clearPendingChallenge();
      return LoginResult(success: true);
    }

    return LoginResult(
      success: false,
      error:
          "Login not yet approved. Please approve on your phone and try again.",
    );
  }

  void _clearPendingChallenge() {
    _pendingChallengeUsername = null;
    _pendingChallengeApiPath = null;
    _encryptedApContext = null;
    _lsdToken = null;
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

    final userId = await getUserId(username);
    var res = await postDocIdJson(ApiDocIds.userInfo, {
      "enable_integrity_filters": true,
      "id": userId,
      "__relay_internal__pv__PolarisCannesGuardianExperienceEnabledrelayprovider":
          true,
      "__relay_internal__pv__PolarisCASB976ProfileEnabledrelayprovider": false,
      "__relay_internal__pv__PolarisWebSchoolsEnabledrelayprovider": false,
      "__relay_internal__pv__PolarisRepostsConsumptionEnabledrelayprovider":
          true,
    }, useApiEndpoint: true);
    var profile = Profile(res["data"]["user"]);
    userInfo[username] = profile;

    await getPosts(username, force: true);

    notifyListeners();

    return profile;
  }

  Future<PaginatedResponse<PostV2>> getPosts(
    String username, {
    String? nextMaxId,
    bool force = false,
  }) async {
    var posts = cache.profiles[username]!.posts;
    if (nextMaxId == null && !force) {
      return posts;
    }

    Map<String, dynamic> variables = {
      "data": {
        "count": 12,
        "include_reel_media_seen_timestamp": true,
        "include_relationship_info": true,
        "latest_besties_reel_media": true,
        "latest_reel_media": true,
      },
      "username": username,

      "__relay_internal__pv__PolarisImmersiveFeedChainingEnabledrelayprovider":
          true,
      "__relay_internal__pv__PolarisAIGMMediaWebLabelEnabledrelayprovider":
          false,
      "__relay_internal__pv__PolarisAIGMAccountLabelEnabledrelayprovider":
          false,
      "__relay_internal__pv__PolarisReelsRecoDebugOverlayEnabledrelayprovider":
          false,
    };
    if (nextMaxId != null) {
      variables["after"] = nextMaxId;
      variables["before"] = null;
      variables["first"] = 12;
      variables["last"] = null;
    }
    var res = await postDocIdJson(ApiDocIds.posts, variables);
    res = res["data"]["xdt_api__v1__feed__user_timeline_graphql_connection"];
    posts.addEdges(
      List<PostV2>.from(
        (res["edges"] as List).map((item) => PostV2(item["node"])),
      ),
    );
    posts.updatePageInfo(res["page_info"] as Map<String, dynamic>);

    notifyListeners();

    return posts;
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

    var res = await getGQLJson(ApiQueryHashes.postInfo, {
      "shortcode": shortCode,
    });
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

  Future<String> getUserId(String username, {bool force = false}) async {
    var profile = cache.profiles[username];
    if (!force && profile != null) {
      return profile.id;
    }

    // var info = await getUserInfo(username, force: force);
    // return info.id;

    var res = await client.get(
      Uri(scheme: "https", host: "www.instagram.com", path: username),
    );
    var matches = userIdRegex.allMatches(res.body);
    if (matches.isNotEmpty) {
      return matches.first.group(1)!;
    }

    throw Exception("User ID not found");
  }

  Future<PaginatedResponse<Reel>> getReels(
    String username, {
    String? endCursor,
    bool force = false,
  }) async {
    var reels = cache.reels;
    if (endCursor == null && !force && reels[username] != null) {
      return reels[username]!;
    }

    Map<String, dynamic> variables = {
      "data": {
        "page_size": 12,
        "target_user_id": await getUserId(username),
        "include_feed_video": true,
      },
      "__relay_internal__pv__PolarisFeedShareMenurelayprovider": false,
    };
    if (endCursor != null) {
      variables["after"] = endCursor;
      variables["before"] = null;
      variables["first"] = 12;
      variables["last"] = null;
    }
    var res = await postDocIdJson(
      ApiDocIds.reels,
      variables,
      referer: "https://www.instagram.com/$username/",
    );
    res = res["data"]["xdt_api__v1__clips__user__connection_v2"];

    var reel = reels[username];
    reel ??= PaginatedResponse<Reel>.empty();
    reel.addEdges(
      List<Reel>.from(res["edges"].map((item) => Reel(item["node"]["media"]))),
    );
    reel.updatePageInfo(res["page_info"]);
    reels[username] = reel;

    notifyListeners();

    return reels[username]!;
  }

  Future<List<Profile>> getSearchRes(String query, {bool force = false}) async {
    var search = cache.search;
    if (!force && search[query] != null) {
      return search[query]!;
    }

    Map<String, dynamic> res;
    if (query == "--recent-searches--") {
      res = await getJson(ApiUrls.recentSearches);
      res = {"users": res["recent"]};
    } else {
      res = await getJson(ApiUrls.search, queryParameters: {"query": query});
    }
    final users = List<Profile>.from(
      (res["users"] ?? []).map((user) => Profile(user["user"])),
    );
    search[query] = users;

    notifyListeners();

    return users;
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
    List<Story> data =
        reelsMedia.isEmpty
            ? []
            : List<Story>.from(
              reelsMedia[0]["items"].map((node) => Story(node)),
            );
    stories[username] = data;

    notifyListeners();

    return data;
  }

  Future<List<Highlight>> getHighlights(
    String username, {
    bool force = false,
  }) async {
    var highlights = cache.highlights;
    if (!force && highlights[username] != null) {
      return highlights[username]!;
    }

    var res = await getGQLJson(ApiQueryHashes.highlights, {
      "user_id": await getUserId(username),
      "include_chaining": false,
      "include_reel": false,
      "include_suggested_users": false,
      "include_logged_out_extras": false,
      "include_highlight_reels": true,
    });
    final edges = res["data"]["user"]["edge_highlight_reels"]["edges"];
    final items = List<Highlight>.from(
      edges.map((edge) => Highlight(edge["node"])),
    );
    highlights[username] = items;

    notifyListeners();

    return items;
  }

  Future<List<Story>> getHighlightItems(
    String highlightId, {
    bool force = false,
  }) async {
    var highlightItems = cache.highlightItems;
    if (!force && highlightItems[highlightId] != null) {
      return highlightItems[highlightId]!;
    }

    var res = await getGQLJson(ApiQueryHashes.highlightItems, {
      "reel_ids": [],
      "tag_names": [],
      "location_ids": [],
      "highlight_reel_ids": [highlightId],
      "precomposed_overlay": false,
    });
    final reelsMedia = res["data"]["reels_media"][0];
    List<Story> items = List<Story>.from(
      reelsMedia["items"].map((node) => Story(node)),
    );
    highlightItems[highlightId] = items;

    notifyListeners();

    return items;
  }

  Future<PaginatedResponse<T>> get<T>({
    required String queryHash,
    required Map<String, dynamic> params,
    required Map<String, dynamic> Function(Map<String, dynamic>) resExtractor,
    required PaginatedResponse<T>? Function(Cache) cacheExtractor,
    required T? Function(Map<String, dynamic>) nodeConverter,
    bool initial = false,
    void Function(Cache)? cacheInitializer,
    bool force = false,
    String referer = "https://www.instagram.com/",
  }) async {
    if (initial) {
      var oldData = cacheExtractor(cache);
      if (!force && oldData != null) {
        return oldData;
      }

      if (cacheInitializer == null) {
        throw ErrorHint(
          "cacheInitializer cannot be null if this is the initial request and there is no cached data available!",
        );
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

    var res = await getGQLJson(queryHash, {
      "first": 25,
      ...params,
    }, referer: referer);
    var newData = resExtractor(res["data"]);
    var oldData = cacheExtractor(cache);
    if (oldData == null) {
      throw ErrorHint(
        "cached data cannot be null if this is not the initial request",
      );
    }
    oldData.updatePageInfo(newData["page_info"]);
    oldData.addEdges(
      List<T>.from(
        (newData["edges"] as List)
            .map((edge) => nodeConverter(edge["node"]))
            .where((node) => node != null),
      ),
    );

    notifyListeners();

    return oldData;
  }

  Future<dynamic> getJson(
    String path, {
    String host = "www.instagram.com",
    Map<String, dynamic>? queryParameters,
  }) async {
    var uri = Uri(
      scheme: "https",
      host: host,
      path: path,
      queryParameters: queryParameters,
    );

    var headers = {
      ...defaultHeaders,
      HttpHeaders.userAgentHeader: ApiUserAgents.getUserAgentByHost(host),
      HttpHeaders.cookieHeader: await cookieJar.getCookiesForHeader(uri),
      "X-CSRFToken": _csrfToken,
    };

    var res = await client.get(uri, headers: headers);

    // TODO: Figure out whether we need to save the cookies here or not
    // cookieJar.saveCookies(uri, res.headers["set-cookie"]);

    return jsonDecode(res.body);
  }

  Future<dynamic> postJson(
    String path, {
    String host = "www.instagram.com",
    Map<String, dynamic>? body,
  }) async {
    var uri = Uri(scheme: "https", host: host, path: path);

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

  Future<dynamic> getMobileJson(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return getJson(
      path,
      host: "i.instagram.com",
      queryParameters: queryParameters,
    );
  }

  Future<dynamic> postMobileJson(String path, {Map<String, dynamic>? body}) {
    return postJson(path, host: "i.instagram.com", body: body);
  }

  Future<dynamic> getCsrfTokenNew({bool? sendCookies}) async {
    var uri = Uri(
      scheme: "https",
      host: "www.instagram.com",
      path: ApiUrls.csrfToken,
    );

    var res = await client.get(
      uri,
      headers: {
        ...defaultHeaders,
        HttpHeaders.userAgentHeader: ApiUserAgents.desktop,
        HttpHeaders.cookieHeader:
            sendCookies != null && sendCookies
                ? await cookieJar.getCookiesForHeader(uri)
                : "",
      },
    );

    final match = windowSharedDataRegex.firstMatch(res.body);
    if (match != null) {
      return match.group(1)!;
    }

    final start = res.body.indexOf("csrf_token");
    return res.body.substring(start, start + 47);
  }

  Future<String> getDtsg() async {
    if (_dtsg != null) {
      return _dtsg!;
    }

    var uri = Uri(scheme: "https", host: "www.instagram.com", path: "/");

    var res = await client.get(
      uri,
      headers: {
        ...defaultHeaders,
        HttpHeaders.userAgentHeader: ApiUserAgents.desktop,
        HttpHeaders.cookieHeader: await cookieJar.getCookiesForHeader(uri),
      },
    );

    final match = dtsgRegex.firstMatch(res.body);
    if (match != null) {
      _dtsg = match.group(1)!;
      return _dtsg!;
    }

    throw Exception("DTSG not found");
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
        "variables": jsonEncode(variables),
      },
    );

    var res = await client.get(
      uri,
      headers: {
        ...defaultHeaders,
        HttpHeaders.refererHeader: referer,
        HttpHeaders.acceptHeader: "*/*",
        HttpHeaders.userAgentHeader: ApiUserAgents.getUserAgentByHost(host),
        HttpHeaders.cookieHeader: await cookieJar.getCookiesForHeader(uri),
        "X-CSRFToken": _csrfToken,
      },
    );

    // TODO: Figure out whether we need to save the cookies here or not
    // cookieJar.saveCookies(uri, res.headers["set-cookie"]);

    return jsonDecode(res.body);
  }

  Future<dynamic> postDocIdJson(
    String docId,
    Map<String, dynamic> variables, {
    String host = "www.instagram.com",
    String referer = "https://www.instagram.com/",
    bool sendCookies = true,
    bool useApiEndpoint = false,
  }) async {
    var uri = Uri(
      scheme: "https",
      host: host,
      path: useApiEndpoint ? "api/graphql" : "graphql/query",
    );

    var headers = {
      ...defaultHeaders,
      HttpHeaders.refererHeader: referer,
      HttpHeaders.acceptHeader: "*/*",
      HttpHeaders.userAgentHeader: ApiUserAgents.getUserAgentByHost(host),
      "X-CSRFToken": _csrfToken,
    };
    if (sendCookies) {
      headers[HttpHeaders.cookieHeader] = await cookieJar.getCookiesForHeader(
        uri,
      );
    }

    var res = await client.post(
      uri,
      body: {
        "doc_id": docId,
        "variables": jsonEncode(variables),
        "server_timestamps": "true",
        "fb_dtsg": await getDtsg(),
      },
      encoding: Encoding.getByName("x-www-form-urlencoded"),
      headers: headers,
    );

    // TODO: Figure out whether we need to save the cookies here or not
    // cookieJar.saveCookies(uri, res.headers["set-cookie"]);

    return jsonDecode(res.body);
  }
}
