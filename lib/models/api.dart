import 'package:flutter/foundation.dart';

class Profile {
  final Map<String, dynamic> _node;
  late final PaginatedResponseV2<PostV2> _posts;
  Profile(this._node) {
    _posts = PaginatedResponseV2<PostV2>.empty();
  }

  String get id => _node["id"];
  String get username => _node["username"];
  String get fullName => _node["full_name"];

  String get profilePicUrl => _node["profile_pic_url"];
  bool get hdProfilePicAvailable => _node["hd_profile_pic_url_info"] != null;
  String get profilePicUrlHd {
    if (hdProfilePicAvailable) {
      return _node["hd_profile_pic_url_info"]["url"];
    }

    return _node["profilePicUrlHd"];
  }

  bool get isPrivate => _node["is_private"];
  bool get followedByViewer => _node["followed_by_viewer"];

  PaginatedResponseV2<PostV2> get posts => _posts;

  void update(Map<String, dynamic> node) {
    _node.addAll(node);
  }
}

class Post {
  final Map<String, dynamic> _node;
  Post(this._node);

  String get id => _node["id"].split("_").first;

  String get username => _node["owner"]["username"];
  String get profilePicUrl => _node["owner"]["profile_pic_url"];

  String get displayUrl => _node["display_url"];

  bool get isVideo => _node["is_video"];

  Map<String, dynamic> get _dimensions => _node["dimensions"];
  int get width => _dimensions["width"];
  int get height => _dimensions["height"];
  double get aspectRatio => height / width;

  List<String> get urls {
    if (isVideo) {
      return [_node["video_url"]];
    }

    if (_node["edge_sidecar_to_children"] != null) {
      return List<String>.from(
          _node["edge_sidecar_to_children"]["edges"].map((img) {
        final node = img["node"];
        if (node["is_video"]) {
          return node["video_url"];
        }
        return node["display_url"];
      }));
    }

    return [displayUrl];
  }

  List<String> get displayUrls {
    if (_node["edge_sidecar_to_children"] != null) {
      return List<String>.from(_node["edge_sidecar_to_children"]["edges"]
          .map((img) => img["node"]["display_url"]));
    }

    return [displayUrl];
  }
}

class PostV2 {
  final Map<String, dynamic> _node;
  PostV2(this._node);

  String get id => _node["id"].split("_").first;

  String get username => _node["user"]["username"];
  String get profilePicUrl => _node["user"]["profile_pic_url"];

  String get displayUrl => _node["image_versions2"]["candidates"].first["url"];

  bool get isVideo => _node["video_duration"] != null;

  Map<String, dynamic> get _dimensions =>
      _node["image_versions2"]["candidates"].first;
  int get width => _dimensions["width"];
  int get height => _dimensions["height"];
  double get aspectRatio => height / width;

  List<String> get urls {
    if (isVideo) {
      return [_node["video_versions"].first["url"]];
    }

    if (_node["carousel_media"] != null) {
      return List<String>.from(_node["carousel_media"].map((node) {
        if (node["video_duration"] != null) {
          return node["video_versions"].first["url"];
        }
        return node["image_versions2"]["candidates"].first["url"];
      }));
    }

    return [displayUrl];
  }

  List<String> get displayUrls {
    if (_node["carousel_media"] != null) {
      return List<String>.from(_node["carousel_media"]
          .map((img) => img["image_versions2"]["candidates"].first["url"]));
    }

    return [displayUrl];
  }
}

class Story extends Post {
  Story(super.node);

  @override
  List<String> get urls => [
        isVideo
            ? _node["video_resources"].first["src"]
            : _node["display_resources"].last["src"]
      ];

  @override
  List<String> get displayUrls => [displayUrl];
}

class Highlight extends Post {
  Highlight(super.node);

  String get title => _node["title"];

  @override
  List<String> get urls => [_node["cover_media_cropped_thumbnail"]["url"]];

  @override
  String get displayUrl => urls.first;
  @override
  List<String> get displayUrls => urls;
}

class Video extends Post {
  Video(super.node);

  @override
  String get displayUrl => _node["image_versions2"]["candidates"].first["url"];

  @override
  List<String> get urls => [_node["video_versions"].first["url"]];

  @override
  List<String> get displayUrls => [displayUrl];
}

class Reel extends Video {
  Reel(super.node);

  @override
  String get displayUrl => _node["image_versions2"]["candidates"].last["url"];
}

class PaginatedResponse<T> {
  final Map<String, dynamic> _node;
  List<T> edges = [];
  PaginatedResponse(this._node, {T Function(dynamic node)? edgeConverter}) {
    if (_node["edges"].isNotEmpty) {
      if (edgeConverter == null) {
        throw ErrorHint("edgeConverter must be passed if edges are passed");
      }
      edges = List<T>.from(
          _node["edges"].map((edge) => edgeConverter(edge["node"])));
    }
  }

  factory PaginatedResponse.empty() {
    return PaginatedResponse<T>({"edges": [], "page_info": null});
  }

  Map<String, dynamic>? get _pageInfo => _node["page_info"];
  bool get hasMoreEdges =>
      _pageInfo == null ? false : _pageInfo!["has_next_page"];
  String? get endCursor => hasMoreEdges ? _pageInfo!["end_cursor"] : null;

  void addEdges(Iterable<T> newEdges) => edges.addAll(newEdges);
  void updatePageInfo(Map<String, dynamic> newInfo) =>
      _node["page_info"] = newInfo;
}

class PaginatedResponseV2<T> {
  final Map<String, dynamic> _node;
  List<T> items = [];
  PaginatedResponseV2(this._node, {T Function(dynamic node)? itemConverter}) {
    if (_node["items"].isNotEmpty) {
      if (itemConverter == null) {
        throw ErrorHint("itemConverter must be passed if items are passed");
      }
      items = List<T>.from(_node["items"].map(itemConverter));
    }
  }

  factory PaginatedResponseV2.empty() {
    return PaginatedResponseV2<T>({"items": [], "paging_info": null});
  }

  Map<String, dynamic>? get _pagingInfo => _node["paging_info"];
  bool get moreAvailable =>
      _pagingInfo == null ? false : _pagingInfo!["more_available"];
  String? get nextMaxId => moreAvailable ? _pagingInfo!["next_max_id"] : null;

  void addEdges(Iterable<T> newItems) => items.addAll(newItems);
  void updatePageInfo(Map<String, dynamic> newInfo) =>
      _node["paging_info"] = newInfo;
}
