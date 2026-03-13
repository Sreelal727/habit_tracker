import 'package:drift/drift.dart';

class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1)();
  TextColumn get icon => text().withDefault(const Constant('star'))();
  IntColumn get color => integer().withDefault(const Constant(0xFF4CAF50))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get frequency => text().withDefault(const Constant('daily'))();
  TextColumn get customDays => text().withDefault(const Constant(''))();
  TextColumn get customization => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
