import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';

import 'package:path/path.dart' as p;

import 'package:downsta/utils.dart';

Future<File> get databaseFile async {
  final dir = await getAppDataStorageDir();
  final path = p.join(dir, 'db.sqlite');
  return File(path);
}

/// Obtains a database connection for running drift in a Dart VM.
DatabaseConnection connect() {
  return DatabaseConnection.delayed(Future(() async {
    return NativeDatabase.createBackgroundConnection(await databaseFile);
  }));
}

Future<void> validateDatabaseSchema(GeneratedDatabase database) async {
  // This method validates that the actual schema of the opened database matches
  // the tables, views, triggers and indices for which drift_dev has generated
  // code.
  if (kDebugMode) {
    await VerifySelf(database).validateDatabaseSchema();
  }
}
