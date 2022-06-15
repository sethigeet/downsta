import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:http/http.dart' as http;

import 'package:path_provider/path_provider.dart';

abstract class URLS {
  static const userInfo =
      "/api/v1/users/web_profile_info/"; // params={"username": USERNAME_TO_GET} mobile
  static const csrfToken = "/accounts/login"; // params={} desktop
  static const login =
      "/login/ajax/"; // data={"enc_password": enc_password, "username": USERNAME} desktop
  static const reels =
      "/api/v1/clips/user/"; // data={"target_user_id": "7305181925"} mobile
  static const following =
      "/api/v1/friendships/{USERID}/following/"; // format={USERID: "47109406312"} mobile
  static const stories = "/api/v1/feed/user/{USERID}/story/"; // mobile
  static const search =
      "/web/search/topsearch/"; // params={"query": SEARCH_TERM} desktop
}

class Api with ChangeNotifier, DiagnosticableTreeMixin {
  http.Client client = http.Client();
  PersistCookieJar cookieJar;

  List<dynamic>? following;
  Map<String, dynamic> userInfo = {};

  String username;

  Api(this.username, this.cookieJar);

  static Future<Api> create(String username) async {
    Directory dir;
    if (Platform.isAndroid) {
      dir = (await getExternalStorageDirectory())!;
    } else {
      dir = await getApplicationSupportDirectory();
    }
    final cookieJar =
        PersistCookieJar(storage: FileStorage("${dir.path}/session-cookies"));

    // TODO: Remove this with actual login cookies
    List<Cookie> cookies = [
      Cookie("sessionid", r""),
      Cookie("mid", r""),
      Cookie("ig_pr", "1"),
      Cookie("ig_vw", "1920"),
      Cookie("ig_cb", "1"),
      Cookie("csrftoken", r""),
      Cookie("s_network", ""),
      Cookie("ds_user_id", ""),
    ];
    await cookieJar.saveFromResponse(
        Uri(scheme: "https", host: "i.instagram.com"), cookies);
    await cookieJar.saveFromResponse(
        Uri(scheme: "https", host: "www.instagram.com"), cookies);

    return Api(username, cookieJar);
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
          ?
          // TODO: user agent should be desktop
          "Instagram 146.0.0.27.125 (iPhone12,1; iOS 13_3; en_US; en-US; scale=2.00; 1656x3584; 190542906)"
          :
          // user agent should be mobile
          "Instagram 146.0.0.27.125 (iPhone12,1; iOS 13_3; en_US; en-US; scale=2.00; 1656x3584; 190542906)",
      HttpHeaders.cookieHeader:
          cookies.map((cookie) => cookie.toString()).join("; "),
      "X-CSRFToken": "",
    });

    // TODO: save the cookies
    // var cookie_header = (res.headers["set-cookie"] ?? "").split(";");
    // await cookieJar!.saveFromResponse(uri, res.cookies);

    return jsonDecode(res.body);
  }

  Future<dynamic> getMobileJson(String path,
      {Map<String, dynamic>? queryParameters}) {
    return getJson(path,
        host: "i.instagram.com", queryParameters: queryParameters);
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
          ?
          // TODO: user agent should be desktop
          "Instagram 146.0.0.27.125 (iPhone12,1; iOS 13_3; en_US; en-US; scale=2.00; 1656x3584; 190542906)"
          :
          // user agent should be mobile
          "Instagram 146.0.0.27.125 (iPhone12,1; iOS 13_3; en_US; en-US; scale=2.00; 1656x3584; 190542906)",
      HttpHeaders.cookieHeader:
          cookies.map((cookie) => cookie.toString()).join("; "),
      "X-CSRFToken": "",
    });

    // TODO: save the cookies
    // var cookie_header = (res.headers["set-cookie"] ?? "").split(";");
    // await cookieJar!.saveFromResponse(uri, res.cookies);

    return jsonDecode(res.body);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(StringProperty("userInfo", userInfo.toString()));
    properties.add(StringProperty("following", following.toString()));
  }
}
