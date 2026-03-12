import 'package:drift/drift.dart';
import 'goals.dart';

class GoalEntries extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text().references(Goals, #id)();
  DateTimeColumn get date => dateTime()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
