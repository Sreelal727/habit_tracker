import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/goal_dao.dart';
import '../../core/database/daos/goal_entry_dao.dart';
import '../../providers/app_providers.dart';

const _uuid = Uuid();

class GoalsState {
  final List<Goal> weeklyGoals;
  final List<Goal> yearlyGoals;
  final Map<String, GoalEntry> weeklyEntries;
  final Map<String, GoalEntry> yearlyEntries;
  final DateTime currentWeekStart;
  final bool isLoading;

  GoalsState({
    this.weeklyGoals = const [],
    this.yearlyGoals = const [],
    this.weeklyEntries = const {},
    this.yearlyEntries = const {},
    DateTime? currentWeekStart,
    this.isLoading = true,
  }) : currentWeekStart = currentWeekStart ?? _getWeekStart(DateTime.now());

  static DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  GoalsState copyWith({
    List<Goal>? weeklyGoals,
    List<Goal>? yearlyGoals,
    Map<String, GoalEntry>? weeklyEntries,
    Map<String, GoalEntry>? yearlyEntries,
    DateTime? currentWeekStart,
    bool? isLoading,
  }) {
    return GoalsState(
      weeklyGoals: weeklyGoals ?? this.weeklyGoals,
      yearlyGoals: yearlyGoals ?? this.yearlyGoals,
      weeklyEntries: weeklyEntries ?? this.weeklyEntries,
      yearlyEntries: yearlyEntries ?? this.yearlyEntries,
      currentWeekStart: currentWeekStart ?? this.currentWeekStart,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool isWeeklyGoalCompleted(String goalId) {
    return weeklyEntries[goalId]?.completed ?? false;
  }

  bool isYearlyGoalCompleted(String goalId) {
    return yearlyEntries[goalId]?.completed ?? false;
  }
}

class GoalsNotifier extends StateNotifier<GoalsState> {
  final GoalDao _goalDao;
  final GoalEntryDao _goalEntryDao;

  GoalsNotifier(this._goalDao, this._goalEntryDao) : super(GoalsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);

    final weeklyGoals = await _goalDao.getGoalsByType('weekly');
    final yearlyGoals = await _goalDao.getGoalsByType('yearly');

    final weeklyEntries =
        await _goalEntryDao.getEntriesForDate(state.currentWeekStart);
    final weeklyMap = <String, GoalEntry>{};
    for (final e in weeklyEntries) {
      weeklyMap[e.goalId] = e;
    }

    final yearStart = DateTime(DateTime.now().year, 1, 1);
    final yearlyEntryList = await _goalEntryDao.getEntriesForDate(yearStart);
    final yearlyMap = <String, GoalEntry>{};
    for (final e in yearlyEntryList) {
      yearlyMap[e.goalId] = e;
    }

    state = state.copyWith(
      weeklyGoals: weeklyGoals,
      yearlyGoals: yearlyGoals,
      weeklyEntries: weeklyMap,
      yearlyEntries: yearlyMap,
      isLoading: false,
    );
  }

  Future<void> toggleWeeklyGoal(String goalId) async {
    await _goalEntryDao.toggleEntry(
        _uuid.v4(), goalId, state.currentWeekStart);
    await load();
  }

  Future<void> toggleYearlyGoal(String goalId) async {
    final yearStart = DateTime(DateTime.now().year, 1, 1);
    await _goalEntryDao.toggleEntry(_uuid.v4(), goalId, yearStart);
    await load();
  }

  Future<void> addGoal(String title, String type) async {
    final goals = await _goalDao.getGoalsByType(type);
    await _goalDao.insertGoal(GoalsCompanion.insert(
      id: _uuid.v4(),
      title: title,
      type: type,
      sortOrder: Value(goals.length),
    ));
    await load();
  }

  Future<void> deleteGoal(String id) async {
    await _goalDao.deleteGoal(id);
    await load();
  }

  void previousWeek() {
    state = state.copyWith(
      currentWeekStart:
          state.currentWeekStart.subtract(const Duration(days: 7)),
    );
    load();
  }

  void nextWeek() {
    state = state.copyWith(
      currentWeekStart: state.currentWeekStart.add(const Duration(days: 7)),
    );
    load();
  }
}

final goalsProvider =
    StateNotifierProvider<GoalsNotifier, GoalsState>((ref) {
  return GoalsNotifier(
    ref.watch(goalDaoProvider),
    ref.watch(goalEntryDaoProvider),
  );
});
