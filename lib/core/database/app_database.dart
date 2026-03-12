import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/habits.dart';
import 'tables/habit_entries.dart';
import 'tables/goals.dart';
import 'tables/goal_entries.dart';
import 'tables/rewards.dart';
import 'tables/user_settings.dart';
import 'daos/habit_dao.dart';
import 'daos/habit_entry_dao.dart';
import 'daos/goal_dao.dart';
import 'daos/goal_entry_dao.dart';
import 'daos/user_settings_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Habits, HabitEntries, Goals, GoalEntries, Rewards, UserSettings],
  daos: [HabitDao, HabitEntryDao, GoalDao, GoalEntryDao, UserSettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;

  factory AppDatabase() {
    return _instance ??= AppDatabase._();
  }

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'habit_tracker.db'));
    return NativeDatabase.createInBackground(file);
  });
}
