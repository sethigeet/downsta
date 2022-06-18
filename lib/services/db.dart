import 'package:downsta/utils.dart';
import 'package:flutter/foundation.dart';

import 'package:hive_flutter/hive_flutter.dart';

class DB with ChangeNotifier, DiagnosticableTreeMixin {
  BoxCollection collection;

  DB(this.collection);

  static Future<DB> create() async {
    final dir = await getAppDataStorageDir();
    final collection = await BoxCollection.open(
      "db",
      {"users"},
      path: dir,
    );

    return DB(collection);
  }

  static Future<void> initDB() async {
    final dir = await getAppDataStorageDir();
    await Hive.initFlutter(dir);
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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties.add(StringProperty("boxes", collection.boxNames.toString()));
  }
}
