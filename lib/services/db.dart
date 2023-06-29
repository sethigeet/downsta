import 'package:drift/drift.dart';

import 'package:downsta/helpers/db_connection/db_connection.dart' as conn;
import 'package:downsta/models/models.dart';

part 'db.g.dart';

@DriftDatabase(tables: [
  HistoryItems,
  Preferences,
], queries: {
  "countHistoryItems": 'SELECT COUNT(*) AS c FROM history_items',
})
class DB extends _$DB {
  DB() : super(conn.connect());

  final Map<String, bool> isDownloadedCache = {};

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (Migrator m) async {
        await m.createAll();
      }, onUpgrade: (Migrator m, int from, int to) async {
        // added the preferences table
        if (from < 2) {
          await m.createTable(preferences);
        } else if (from < 3) {
          await m.alterTable(TableMigration(historyItems, columnTransformer: {
            historyItems.downloadTime: historyItems.downloadTime.cast<int>(),
          }));
        }
      }, beforeOpen: (details) async {
        await conn.validateDatabaseSchema(this);
      });

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
}
