import 'package:drift/drift.dart';

class HistoryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get postId => text().withLength(max: 100)();
  TextColumn get username => text().withLength(max: 100)();
  TextColumn get coverImgUrl => text()();
  TextColumn get imgUrls => text()();
  DateTimeColumn get downloadTime =>
      dateTime().withDefault(currentDateAndTime)();
}
