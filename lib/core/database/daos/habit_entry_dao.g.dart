// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_entry_dao.dart';

// ignore_for_file: type=lint
mixin _$HabitEntryDaoMixin on DatabaseAccessor<AppDatabase> {
  $HabitsTable get habits => attachedDatabase.habits;
  $HabitEntriesTable get habitEntries => attachedDatabase.habitEntries;
  HabitEntryDaoManager get managers => HabitEntryDaoManager(this);
}

class HabitEntryDaoManager {
  final _$HabitEntryDaoMixin _db;
  HabitEntryDaoManager(this._db);
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db.attachedDatabase, _db.habits);
  $$HabitEntriesTableTableManager get habitEntries =>
      $$HabitEntriesTableTableManager(_db.attachedDatabase, _db.habitEntries);
}
