import 'package:flutter/foundation.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'package:downsta/models/history_item.dart';
import 'package:downsta/utils.dart';

class DB with ChangeNotifier, DiagnosticableTreeMixin {
  BoxCollection collection;

  DB(this.collection);

  static Future<DB> create() async {
    final dir = await getAppDataStorageDir();
    final collection = await BoxCollection.open(
      "db",
      {"users", "history"},
      path: dir,
    );

    return DB(collection);
  }

  static Future<void> initDB() async {
    final dir = await getAppDataStorageDir();
    await Hive.initFlutter(dir);
    Hive.registerAdapter(HistoryItemAdapter());
  }

  Future<String?> getLastLoggedInUser() async {
    final usersBox = await collection.openBox("users");
    return await usersBox.get("lastLoggedInUser");
  }

  Future<List<String>> getLoggedInUsers() async {
    final usersBox = await collection.openBox("users");
    List<dynamic>? loggedInUsers = await usersBox.get("loggedInUsers");
    if (loggedInUsers == null) {
      await usersBox.put("loggedInUsers", []);
      loggedInUsers = [];
    }
    return loggedInUsers.cast<String>();
  }

  Future<void> setLastLoggedInUser(String username) async {
    final usersBox = await collection.openBox("users");
    await collection.transaction(
      () async {
        await usersBox.put("lastLoggedInUser", username);
        final List<dynamic> loggedInUsersList =
            await usersBox.get("loggedInUsers");
        final loggedInUsers = Set.from(loggedInUsersList);
        loggedInUsers.add(username);
        await usersBox.put("loggedInUsers", List.from(loggedInUsers));
      },
      boxNames: ["users"],
      readOnly: false,
    );

    notifyListeners();
  }

  Future<List<HistoryItem>> getHistoryItems() async {
    final historyBox = await collection.openBox<HistoryItem>("history");
    var items = await historyBox.getAllValues();
    var vals = items.values.toList()
      // Sort the vals so that the newest download is at the top!
      ..sort((a, b) => a.timeDownloaded.compareTo(b.timeDownloaded) * -1);
    return vals;
  }

  Future<bool> isPostDownloaded(String id) async {
    final historyBox = await collection.openBox<HistoryItem>("history");
    final item = await historyBox.get(id);
    return item != null;
  }

  Future<void> saveItemsToHistory(List<HistoryItem> items) async {
    final historyBox = await collection.openBox<HistoryItem>("history");
    await collection.transaction(
      () async {
        for (var item in items) {
          await historyBox.put(item.postId, item);
        }
      },
      boxNames: ["history"],
      readOnly: false,
    );

    notifyListeners();
  }

  Future<void> saveItemToHistory(HistoryItem item) async {
    final historyBox = await collection.openBox<HistoryItem>("history");
    await collection.transaction(
      () async {
        await historyBox.put(item.postId, item);
      },
      boxNames: ["history"],
      readOnly: false,
    );

    notifyListeners();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(StringProperty("boxes", collection.boxNames.toString()));
  }
}
