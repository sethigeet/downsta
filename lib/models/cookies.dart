import 'package:drift/drift.dart';

class Cookies extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().withLength(max: 100)();
  TextColumn get index => text().withDefault(const Constant(""))();
  TextColumn get domains => text().withDefault(const Constant(""))();
}
