import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import 'package:downsta/models/models.dart';
import 'package:downsta/utils.dart';

part 'db.g.dart';

@DriftDatabase(tables: [
  HistoryItems,
  Preferences,
], queries: {
  "countHistoryItems": 'SELECT COUNT(*) AS c FROM history_items',
})
class DB extends _$DB {
  DB() : super(DB._openConnection());

  final Map<String, bool> _isDownloadedCache = {};

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (Migrator m) async {
        await m.createAll();
      }, onUpgrade: (Migrator m, int from, int to) async {
        // added the preferences table
        if (from < 2) {
          m.createTable(preferences);
        }
      });

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dir = await getAppDataStorageDir();
      final file = File(p.join(dir, 'db.sqlite'));
      return NativeDatabase(file);
    });
  }

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
      await query.insert(PreferencesCompanion.insert(
        lastLoggedInUser: Value(username),
        loggedInUsers: Value(username),
      ));
    } else {
      var query = update(preferences);
      await query.write(PreferencesCompanion(
        lastLoggedInUser: Value(username),
        loggedInUsers: Value(
          List.from(
            Set.from(loggedInUsers)..add(username),
          ).join(","),
        ),
      ));
    }
  }

  Future<List<String>> removeLoggedInUser(String username) async {
    var loggedInUsers = await getLoggedInUsers();
    if (loggedInUsers == null) {
      return [];
    }

    loggedInUsers = List.from(Set.from(loggedInUsers)..remove(username));

    var query = update(preferences);
    await query.write(PreferencesCompanion(
      lastLoggedInUser:
          Value(loggedInUsers.isEmpty ? null : loggedInUsers.first),
      loggedInUsers: Value(loggedInUsers.join(",")),
    ));

    return loggedInUsers;
  }

  Future<List<HistoryItem>> getHistoryItems({int? offset}) async {
    var query = select(historyItems)
      ..orderBy([
        (item) =>
            OrderingTerm(expression: item.downloadTime, mode: OrderingMode.desc)
      ])
      ..limit(10, offset: offset);

    return query.get();
  }

  Future<int> getTotalHistoryItems() async {
    return countHistoryItems().getSingle();
  }

  Future<bool> isPostDownloaded(String postId) async {
    var cached = _isDownloadedCache[postId];
    if (cached != null) {
      return cached;
    }

    var query = select(historyItems)
      ..where((item) => item.postId.equals(postId));
    var res = await query.getSingleOrNull();
    var isDownloaded = res != null;
    _isDownloadedCache[postId] = isDownloaded;
    return isDownloaded;
  }

  Future<void> saveItemsToHistory(List<HistoryItemsCompanion> items) async {
    await batch((batch) {
      batch.insertAll<HistoryItems, HistoryItem>(historyItems, items);
    });
    for (var item in items) {
      _isDownloadedCache[item.postId.value] = true;
    }
  }

  Future<void> saveItemToHistory(HistoryItemsCompanion item) async {
    await into(historyItems).insert(item);
    _isDownloadedCache[item.postId.value] = true;
  }
}
