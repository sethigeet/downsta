import 'package:drift/drift.dart';

class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().withLength(max: 100).unique()();
  DateTimeColumn get bookmarkTime =>
      dateTime().withDefault(currentDateAndTime)();
}
