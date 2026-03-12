import 'package:drift/drift.dart';

class Rewards extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get habitIds => text().withDefault(const Constant(''))();
  DateTimeColumn get earnedAt => dateTime()();
  IntColumn get streakDays => integer().withDefault(const Constant(21))();

  @override
  Set<Column> get primaryKey => {id};
}
