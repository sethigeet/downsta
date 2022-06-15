import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:http/http.dart' as http;

import 'package:path_provider/path_provider.dart';

final windowSharedDataRegex = RegExp(r"window\._sharedData = (.*);</script>");
final cookieSplitRegex = RegExp(r',(?=[^ ])');

abstract class URLS {
  // desktop
  static const csrfToken = "/accounts/login";
  // data={"enc_password": enc_password, "username": USERNAME} desktop
  static const login = "/accounts/login/ajax/";
  static const loginCheck = "/accounts/login/";

  // data={"target_user_id": "<userid>"} mobile
  static const reels = "/api/v1/clips/user/";
  // params={"username": USERNAME_TO_GET} mobile
  static const userInfo = "/api/v1/users/web_profile_info/";

  static const following = "/api/v1/friendships/{USERID}/following/";
  // mobile
  static const stories = "/api/v1/feed/user/{USERID}/story/";

  // params={"query": SEARCH_TERM} desktop
  static const search = "/web/search/topsearch/";
}

class Api with ChangeNotifier, DiagnosticableTreeMixin {
  final http.Client client = http.Client();
  final PersistCookieJar cookieJar;
  String _csrfToken;

  List<dynamic>? following;
  Map<String, dynamic> userInfo = {};
  bool? isLoggedIn;

  String username;

  Api(this.username, this.cookieJar, this._csrfToken);

  static Future<Api> create(String username) async {
    Directory dir;
    if (Platform.isAndroid) {
      dir = (await getExternalStorageDirectory())!;
    } else {
      dir = await getApplicationSupportDirectory();
    }
    final cookieJar = PersistCookieJar(
        storage: FileStorage("${dir.path}/session-cookies-$username"));

    return Api(username, cookieJar, "");
  }

  Future<bool> getIsLoggedIn() async {
    if (isLoggedIn != null) {
      return isLoggedIn!;
    }

    var uri = Uri(
      scheme: "https",
      host: "www.instagram.com",
      path: URLS.loginCheck,
    );
    var cookies = await cookieJar.loadForRequest(uri);
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
      HttpHeaders.acceptEncodingHeader: "gzip, deflate",
      HttpHeaders.acceptLanguageHeader: "en-US,en;q=0.8",
      HttpHeaders.refererHeader: "https://www.instagram.com/",
      HttpHeaders.userAgentHeader:
          "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.131 Safari/537.36",
      HttpHeaders.cookieHeader:
          cookies.map((cookie) => cookie.toString()).join("; "),
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

  Future<String?> login(String username, String password) async {
    if (isLoggedIn != null && isLoggedIn!) {
      return null;
    }

    final csrfRes = await getWindowSharedData(URLS.csrfToken);
    _csrfToken = csrfRes["config"]["csrf_token"];

    sleep(const Duration(seconds: 1));

    final encPassword =
        '#PWD_INSTAGRAM_BROWSER:0:${DateTime.now().millisecondsSinceEpoch}:$password';
    final uri = Uri(
      scheme: "https",
      host: "www.instagram.com",
      path: URLS.login,
    );
    final cookies = await cookieJar.loadForRequest(uri);
    final res = await client.post(
      uri,
      headers: {
        HttpHeaders.acceptEncodingHeader: "gzip, deflate",
        HttpHeaders.acceptLanguageHeader: "en-US,en;q=0.8",
        HttpHeaders.refererHeader: "https://www.instagram.com/",
        HttpHeaders.userAgentHeader:
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.131 Safari/537.36",
        HttpHeaders.cookieHeader:
            cookies.map((cookie) => cookie.toString()).join("; "),
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

    this.username = username;
    saveCookies(uri, res.headers["set-cookie"]);

    return null;
  }

  Future<Map<String, dynamic>> getUserInfo(String username,
      {bool? force}) async {
    if ((force == null || !force) && userInfo[username] != null) {
      return userInfo[username];
    }

    var res = await getMobileJson(
      URLS.userInfo,
      queryParameters: {"username": username},
    );
    var info = res["data"]["user"];
    userInfo[username] = info;

    notifyListeners();

    return info;
  }

  Future<String> getUserId(String username, {bool? force}) async {
    if ((force == null || !force) && userInfo[username] != null) {
      return userInfo[username]["id"];
    }

    var info = await getUserInfo(username, force: force);
    return info["id"];
  }

  Future<List<dynamic>> getFollowing({bool? force}) async {
    if ((force == null || !force) && this.following != null) {
      return this.following!;
    }

    var userId = await getUserId(username);
    var res =
        await getMobileJson(URLS.following.replaceAll("{USERID}", userId));

    var following = res["users"];
    this.following = following;

    notifyListeners();

    return following;
  }

  Future<Map<String, dynamic>> getMorePosts(
      String username, String endCursor) async {
    final userId = userInfo[username]["id"];
    var res = await getGQLJson("003056d32c2554def87228bc3fd9668a",
        {"id": userId, "first": 25, "after": endCursor});
    var media = res["data"]["user"]["edge_owner_to_timeline_media"];

    var oldMedia = userInfo[username]["edge_owner_to_timeline_media"];
    oldMedia["page_info"]["has_next_page"] =
        media["page_info"]["has_next_page"];
    oldMedia["page_info"]["end_cursor"] = media["page_info"]["end_cursor"];
    oldMedia["edges"].addAll(media["edges"]);

    notifyListeners();

    return media;
  }

  Future<dynamic> getJson(String path,
      {String host = "www.instagram.com",
      Map<String, dynamic>? queryParameters}) async {
    var uri = Uri(
        scheme: "https",
        host: host,
        path: path,
        queryParameters: queryParameters);

    var cookies = await cookieJar.loadForRequest(uri);
    var res = await client.get(uri, headers: {
      HttpHeaders.acceptEncodingHeader: "gzip, deflate",
      HttpHeaders.acceptLanguageHeader: "en-US,en;q=0.8",
      HttpHeaders.refererHeader: "https://www.instagram.com/",
      HttpHeaders.userAgentHeader: host.contains("www")
          ? "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.131 Safari/537.36"
          :
          // user agent should be mobile
          "Instagram 146.0.0.27.125 (iPhone12,1; iOS 13_3; en_US; en-US; scale=2.00; 1656x3584; 190542906)",
      HttpHeaders.cookieHeader:
          cookies.map((cookie) => cookie.toString()).join("; "),
      "X-CSRFToken": _csrfToken,
    });

    // saveCookies(uri, res.headers["set-cookie"]);

    return jsonDecode(res.body);
  }

  Future<dynamic> getMobileJson(String path,
      {Map<String, dynamic>? queryParameters}) {
    return getJson(path,
        host: "i.instagram.com", queryParameters: queryParameters);
  }

  Future<dynamic> getWindowSharedData(String path,
      {String host = "www.instagram.com",
      Map<String, dynamic>? queryParameters}) async {
    var uri = Uri(
        scheme: "https",
        host: host,
        path: path,
        queryParameters: queryParameters);

    var cookies = await cookieJar.loadForRequest(uri);
    var res = await client.get(uri, headers: {
      HttpHeaders.acceptEncodingHeader: "gzip, deflate",
      HttpHeaders.acceptLanguageHeader: "en-US,en;q=0.8",
      HttpHeaders.refererHeader: "https://www.instagram.com/",
      HttpHeaders.userAgentHeader: host.contains("www")
          ? "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.131 Safari/537.36"
          :
          // user agent should be mobile
          "Instagram 146.0.0.27.125 (iPhone12,1; iOS 13_3; en_US; en-US; scale=2.00; 1656x3584; 190542906)",
      HttpHeaders.cookieHeader:
          cookies.map((cookie) => cookie.toString()).join("; "),
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

    var cookies = await cookieJar.loadForRequest(uri);
    var res = await client.get(uri, headers: {
      HttpHeaders.acceptEncodingHeader: "gzip, deflate",
      HttpHeaders.acceptLanguageHeader: "en-US,en;q=0.8",
      HttpHeaders.refererHeader: "https://www.instagram.com/",
      HttpHeaders.acceptHeader: "*/*",
      HttpHeaders.userAgentHeader: host.contains("www")
          ? "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.131 Safari/537.36"
          :
          // user agent should be mobile
          "Instagram 146.0.0.27.125 (iPhone12,1; iOS 13_3; en_US; en-US; scale=2.00; 1656x3584; 190542906)",
      HttpHeaders.cookieHeader:
          cookies.map((cookie) => cookie.toString()).join("; "),
      "X-CSRFToken": _csrfToken,
    });

    // saveCookies(uri, res.headers["set-cookie"]);

    return jsonDecode(res.body);
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
    await cookieJar.saveFromResponse(
        Uri(scheme: "https", host: "i.instagram.com"), parsedCookies);
    await cookieJar.saveFromResponse(
        Uri(scheme: "https", host: "www.instagram.com"), parsedCookies);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(StringProperty("userInfo", userInfo.toString()));
    properties.add(StringProperty("following", following.toString()));
  }
}
