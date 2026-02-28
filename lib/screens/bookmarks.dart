import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:downsta/services/services.dart';
import 'package:downsta/widgets/widgets.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  static const routeName = "/bookmarks";

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final _scrollController = ScrollController();
  List<Bookmark>? bookmarkItems;
  int? totalBookmarks;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_scrollListener);

    final db = Provider.of<DB>(context, listen: false);
    db.getBookmarks().then(
      (items) => db.getTotalBookmarks().then(
        (total) => setState(() {
          bookmarkItems = items;
          totalBookmarks = total;
        }),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();

    super.dispose();
  }

  void _scrollListener() async {
    if (bookmarkItems == null ||
        totalBookmarks == null ||
        bookmarkItems!.length == totalBookmarks!) {
      return;
    }

    if (_scrollController.position.extentAfter == 0) {
      final db = Provider.of<DB>(context, listen: false);
      db
          .getBookmarks(offset: bookmarkItems!.length)
          .then((items) => setState(() => bookmarkItems!.addAll(items)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DB>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: const Text("Bookmarks")),
      body: bookmarkItems == null
          ? const Center(child: CircularProgressIndicator())
          : bookmarkItems!.isEmpty
              ? const NoContent(
                  message: "No bookmarked profiles yet",
                  icon: Icons.bookmark_outline_rounded,
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: bookmarkItems!.length,
                  itemBuilder: (context, index) {
                    final item = bookmarkItems![index];
                    return BookmarkCard(
                      item: item,
                      onRemove: () {
                        db.removeBookmark(item.id);
                        setState(() {
                          bookmarkItems!.removeAt(index);
                          totalBookmarks = totalBookmarks! - 1;
                        });
                      },
                    );
                  },
                ),
    );
  }
}
