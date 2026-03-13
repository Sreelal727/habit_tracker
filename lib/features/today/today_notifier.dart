import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/habit_dao.dart';
import '../../core/database/daos/habit_entry_dao.dart';
import '../../core/database/daos/goal_dao.dart';
import '../../core/database/daos/goal_entry_dao.dart';
import '../../providers/app_providers.dart';

const _uuid = Uuid();

class TodayState {
  final List<Habit> habits;
  final Map<String, HabitEntry> habitEntries;
  final List<Goal> dailyGoals;
  final Map<String, GoalEntry> goalEntries;
  final Map<String, int> streaks;
  final bool isLoading;

  const TodayState({
    this.habits = const [],
    this.habitEntries = const {},
    this.dailyGoals = const [],
    this.goalEntries = const {},
    this.streaks = const {},
    this.isLoading = true,
  });

  TodayState copyWith({
    List<Habit>? habits,
    Map<String, HabitEntry>? habitEntries,
    List<Goal>? dailyGoals,
    Map<String, GoalEntry>? goalEntries,
    Map<String, int>? streaks,
    bool? isLoading,
  }) {
    return TodayState(
      habits: habits ?? this.habits,
      habitEntries: habitEntries ?? this.habitEntries,
      dailyGoals: dailyGoals ?? this.dailyGoals,
      goalEntries: goalEntries ?? this.goalEntries,
      streaks: streaks ?? this.streaks,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool isHabitCompleted(String habitId) {
    return habitEntries[habitId]?.completed ?? false;
  }

  bool isGoalCompleted(String goalId) {
    return goalEntries[goalId]?.completed ?? false;
  }
}

class TodayNotifier extends StateNotifier<TodayState> {
  final HabitDao _habitDao;
  final HabitEntryDao _habitEntryDao;
  final GoalDao _goalDao;
  final GoalEntryDao _goalEntryDao;

  StreamSubscription? _habitsSub;
  StreamSubscription? _entriesSub;
  StreamSubscription? _goalsSub;
  StreamSubscription? _goalEntriesSub;

  TodayNotifier(
    this._habitDao,
    this._habitEntryDao,
    this._goalDao,
    this._goalEntryDao,
  ) : super(const TodayState()) {
    _init();
  }

  Future<void> _init() async {
    _watchHabits();
    _watchEntries();
    _watchGoals();
    _watchGoalEntries();
  }

  void _watchHabits() {
    _habitsSub = _habitDao.watchActiveHabits().listen((habits) async {
      final streaks = <String, int>{};
      for (final h in habits) {
        streaks[h.id] = await _habitEntryDao.getConsecutiveDays(h.id);
      }
      state = state.copyWith(habits: habits, streaks: streaks, isLoading: false);
    });
  }

  void _watchEntries() {
    _entriesSub = _habitEntryDao.watchEntriesForDate(DateTime.now()).listen((entries) {
      final map = <String, HabitEntry>{};
      for (final e in entries) {
        map[e.habitId] = e;
      }
      state = state.copyWith(habitEntries: map);
    });
  }

  void _watchGoals() {
    _goalsSub = _goalDao.watchGoalsByType('daily').listen((goals) {
      state = state.copyWith(dailyGoals: goals);
    });
  }

  void _watchGoalEntries() {
    _goalEntriesSub = _goalEntryDao.watchEntriesForDate(DateTime.now()).listen((entries) {
      final map = <String, GoalEntry>{};
      for (final e in entries) {
        map[e.goalId] = e;
      }
      state = state.copyWith(goalEntries: map);
    });
  }

  Future<void> toggleHabit(String habitId) async {
    await _habitEntryDao.toggleEntry(_uuid.v4(), habitId, DateTime.now());
    // Update streak after toggle
    final streak = await _habitEntryDao.getConsecutiveDays(habitId);
    state = state.copyWith(
      streaks: {...state.streaks, habitId: streak},
    );
  }

  Future<void> toggleGoal(String goalId) async {
    await _goalEntryDao.toggleEntry(_uuid.v4(), goalId, DateTime.now());
  }

  Future<void> addHabit(String name, String icon, int color) async {
    final habits = await _habitDao.getActiveHabits();
    await _habitDao.insertHabit(HabitsCompanion.insert(
      id: _uuid.v4(),
      name: name,
      icon: Value(icon),
      color: Value(color),
      sortOrder: Value(habits.length),
    ));
  }

  Future<void> addDailyGoal(String title) async {
    final goals = await _goalDao.getGoalsByType('daily');
    await _goalDao.insertGoal(GoalsCompanion.insert(
      id: _uuid.v4(),
      title: title,
      type: 'daily',
      sortOrder: Value(goals.length),
    ));
  }

  Future<void> deleteDailyGoal(String id) async {
    await _goalDao.deleteGoal(id);
  }

  @override
  void dispose() {
    _habitsSub?.cancel();
    _entriesSub?.cancel();
    _goalsSub?.cancel();
    _goalEntriesSub?.cancel();
    super.dispose();
  }
}

final todayProvider = StateNotifierProvider<TodayNotifier, TodayState>((ref) {
  return TodayNotifier(
    ref.watch(habitDaoProvider),
    ref.watch(habitEntryDaoProvider),
    ref.watch(goalDaoProvider),
    ref.watch(goalEntryDaoProvider),
  );
});
