// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_entry_dao.dart';

// ignore_for_file: type=lint
mixin _$GoalEntryDaoMixin on DatabaseAccessor<AppDatabase> {
  $GoalsTable get goals => attachedDatabase.goals;
  $GoalEntriesTable get goalEntries => attachedDatabase.goalEntries;
  GoalEntryDaoManager get managers => GoalEntryDaoManager(this);
}

class GoalEntryDaoManager {
  final _$GoalEntryDaoMixin _db;
  GoalEntryDaoManager(this._db);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db.attachedDatabase, _db.goals);
  $$GoalEntriesTableTableManager get goalEntries =>
      $$GoalEntriesTableTableManager(_db.attachedDatabase, _db.goalEntries);
}
