import 'package:hive/hive.dart';

part 'history_item.g.dart';

@HiveType(typeId: 1)
class HistoryItem extends HiveObject {
  @HiveField(0)
  final String postId;

  @HiveField(1)
  final String coverImgUrl;

  @HiveField(2)
  final List<String> imageUrls;

  @HiveField(3)
  final String username;

  @HiveField(4)
  final DateTime timeDownloaded;

  HistoryItem({
    required this.postId,
    required this.coverImgUrl,
    required this.imageUrls,
    required this.username,
    required this.timeDownloaded,
  });

  static HistoryItem create({
    required String postId,
    required String coverImgUrl,
    required List<String> imageUrls,
    required String username,
  }) {
    return HistoryItem(
      postId: postId,
      coverImgUrl: coverImgUrl,
      imageUrls: imageUrls,
      username: username,
      timeDownloaded: DateTime.now(),
    );
  }
}
