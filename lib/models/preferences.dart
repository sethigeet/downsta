import 'package:drift/drift.dart';

class Preferences extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get lastLoggedInUser => text().withLength(max: 100).nullable()();
  TextColumn get loggedInUsers => text().nullable()();
}
