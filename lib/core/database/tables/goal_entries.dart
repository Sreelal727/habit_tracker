import 'package:drift/drift.dart';
import 'goals.dart';

class GoalEntries extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text().references(Goals, #id)();
  DateTimeColumn get date => dateTime()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get completionPercent => integer().withDefault(const Constant(0))();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
