import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/app_database.dart';
import '../core/database/daos/habit_dao.dart';
import '../core/database/daos/habit_entry_dao.dart';
import '../core/database/daos/goal_dao.dart';
import '../core/database/daos/goal_entry_dao.dart';
import '../core/database/daos/user_settings_dao.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final habitDaoProvider = Provider<HabitDao>((ref) {
  return ref.watch(databaseProvider).habitDao;
});

final habitEntryDaoProvider = Provider<HabitEntryDao>((ref) {
  return ref.watch(databaseProvider).habitEntryDao;
});

final goalDaoProvider = Provider<GoalDao>((ref) {
  return ref.watch(databaseProvider).goalDao;
});

final goalEntryDaoProvider = Provider<GoalEntryDao>((ref) {
  return ref.watch(databaseProvider).goalEntryDao;
});

final userSettingsDaoProvider = Provider<UserSettingsDao>((ref) {
  return ref.watch(databaseProvider).userSettingsDao;
});
