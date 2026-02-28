import 'package:drift/drift.dart';

import 'package:downsta/helpers/db_connection/db_connection.dart' as conn;
import 'package:downsta/models/models.dart';

part 'db.g.dart';

@DriftDatabase(
  tables: [HistoryItems, Preferences, Cookies, Bookmarks],
  queries: {
    "countHistoryItems": 'SELECT COUNT(*) AS c FROM history_items',
    "countBookmarks": 'SELECT COUNT(*) AS c FROM bookmarks',
  },
)
class DB extends _$DB {
  DB() : super(conn.connect());

  final Map<String, bool> isDownloadedCache = {};
  final Map<String, bool> isBookmarkedCache = {};

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // add/update the preferences table
      if (from < 2) {
        await m.createTable(preferences);
      } else if (from < 3) {
        await m.alterTable(
          TableMigration(
            historyItems,
            columnTransformer: {
              historyItems.downloadTime: historyItems.downloadTime.cast<int>(),
            },
          ),
        );
      }

      // add the cookies table
      if (from < 4) {
        await m.createTable(cookies);
      }

      // add organizeByUsername column to preferences
      if (from < 5) {
        await m.addColumn(preferences, preferences.organizeByUsername);
      }

      // add the bookmarks table
      if (from < 6) {
        await m.createTable(bookmarks);
      }
    },
    beforeOpen: (details) async {
      await conn.validateDatabaseSchema(this);
    },
  );

  Future<String?> getLastLoggedInUser() async {
    var query = select(preferences);
    var res = await query.getSingleOrNull();
    if (res == null) {
      return null;
    }

    return res.lastLoggedInUser;
  }

  Future<List<String>?> getLoggedInUsers() async {
    var query = select(preferences);
    var res = await query.getSingleOrNull();
    if (res == null) {
      return null;
    }

    return res.loggedInUsers?.split(",") ?? [];
  }

  Future<void> setLastLoggedInUser(String username) async {
    var loggedInUsers = await getLoggedInUsers();
    if (loggedInUsers == null) {
      var query = into(preferences);
      await query.insert(
        PreferencesCompanion.insert(
          lastLoggedInUser: Value(username),
          loggedInUsers: Value(username),
        ),
      );
    } else {
      var query = update(preferences);
      await query.write(
        PreferencesCompanion(
          lastLoggedInUser: Value(username),
          loggedInUsers: Value(
            List.from(Set.from(loggedInUsers)..add(username)).join(","),
          ),
        ),
      );
    }
  }

  Future<List<String>> removeLoggedInUser(String username) async {
    var loggedInUsers = await getLoggedInUsers();
    if (loggedInUsers == null) {
      return [];
    }

    loggedInUsers = List.from(Set.from(loggedInUsers)..remove(username));

    var query = update(preferences);
    await query.write(
      PreferencesCompanion(
        lastLoggedInUser: Value(
          loggedInUsers.isEmpty ? null : loggedInUsers.first,
        ),
        loggedInUsers: Value(loggedInUsers.join(",")),
      ),
    );

    return loggedInUsers;
  }

  Future<List<HistoryItem>> getHistoryItems({int? offset}) async {
    var query =
        select(historyItems)
          ..orderBy([
            (item) => OrderingTerm(
              expression: item.downloadTime,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(10, offset: offset);

    return query.get();
  }

  Future<int> getTotalHistoryItems() async {
    return countHistoryItems().getSingle();
  }

  Future<bool> isPostDownloaded(String postId) async {
    var cached = isDownloadedCache[postId];
    if (cached != null) {
      return cached;
    }

    var query = select(historyItems)
      ..where((item) => item.postId.equals(postId));
    var res = await query.getSingleOrNull();
    var isDownloaded = res != null;
    isDownloadedCache[postId] = isDownloaded;
    return isDownloaded;
  }

  Future<void> saveItemsToHistory(List<HistoryItemsCompanion> items) async {
    await batch((batch) {
      batch.insertAll<HistoryItems, HistoryItem>(historyItems, items);
    });
    for (var item in items) {
      isDownloadedCache[item.postId.value] = true;
    }
  }

  Future<void> saveItemToHistory(HistoryItemsCompanion item) async {
    await into(historyItems).insert(item);
    isDownloadedCache[item.postId.value] = true;
  }

  Future<void> deleteItemFromHistory(int id) async {
    var query = delete(historyItems)..where((item) => item.id.equals(id));
    await query.go();
  }

  // ── Bookmarks ──

  Future<List<Bookmark>> getBookmarks({int? offset}) async {
    var query =
        select(bookmarks)
          ..orderBy([
            (item) => OrderingTerm(
              expression: item.bookmarkTime,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(10, offset: offset);

    return query.get();
  }

  Future<int> getTotalBookmarks() async {
    return countBookmarks().getSingle();
  }

  Future<bool> isProfileBookmarked(String username) async {
    var cached = isBookmarkedCache[username];
    if (cached != null) return cached;

    var query = select(bookmarks)
      ..where((item) => item.username.equals(username));
    var res = await query.getSingleOrNull();
    var isBookmarked = res != null;
    isBookmarkedCache[username] = isBookmarked;
    return isBookmarked;
  }

  Future<void> addBookmark(BookmarksCompanion item) async {
    await into(bookmarks).insert(item);
    isBookmarkedCache[item.username.value] = true;
  }

  Future<void> removeBookmark(int id) async {
    final item =
        await (select(bookmarks)
          ..where((b) => b.id.equals(id))).getSingleOrNull();
    if (item != null) {
      isBookmarkedCache[item.username] = false;
    }
    await (delete(bookmarks)..where((b) => b.id.equals(id))).go();
  }

  Future<void> removeBookmarkByUsername(String username) async {
    isBookmarkedCache[username] = false;
    await (delete(bookmarks)..where((b) => b.username.equals(username))).go();
  }

  Future<bool> getOrganizeByUsername() async {
    var query = select(preferences);
    var res = await query.getSingleOrNull();
    if (res == null) {
      return true; // default
    }
    return res.organizeByUsername;
  }

  Future<void> setOrganizeByUsername(bool value) async {
    var existing = await select(preferences).getSingleOrNull();
    if (existing == null) {
      await into(
        preferences,
      ).insert(PreferencesCompanion.insert(organizeByUsername: Value(value)));
    } else {
      await (update(
        preferences,
      )).write(PreferencesCompanion(organizeByUsername: Value(value)));
    }
  }

  Future<Cookie?> getCookie(String username) =>
      (select(
        cookies,
      )..where((cookie) => cookie.username.equals(username))).getSingleOrNull();

  Future<void> createCookie(String username) async {
    if ((await getCookie(username)) != null) {
      return;
    }

    await into(cookies).insert(CookiesCompanion.insert(username: username));
  }

  Future<void> updateCookie(String username, CookiesCompanion changes) =>
      (update(cookies)
        ..where((cookie) => cookie.username.equals(username))).write(changes);

  Future<void> deleteCookie(String username) =>
      (delete(cookies)
        ..where((cookie) => cookie.username.equals(username))).go();
}
