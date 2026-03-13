import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/habit_dao.dart';
import '../../core/database/daos/habit_entry_dao.dart';
import '../../providers/app_providers.dart';

class StatsState {
  final List<Habit> habits;
  final Map<String, double> completionRates; // habitId -> 0.0 to 1.0
  final Map<DateTime, int> dailyHabitCounts; // date -> count of completed habits
  final Map<DateTime, Map<String, bool>> calendarData; // date -> habitId -> completed
  final DateTime currentMonth;
  final bool isLoading;
  final int periodDays; // 7, 30, or 90
  final String? filterHabitId; // null = show all

  StatsState({
    this.habits = const [],
    this.completionRates = const {},
    this.dailyHabitCounts = const {},
    this.calendarData = const {},
    DateTime? currentMonth,
    this.isLoading = true,
    this.periodDays = 30,
    this.filterHabitId,
  }) : currentMonth = currentMonth ?? DateTime(DateTime.now().year, DateTime.now().month);

  StatsState copyWith({
    List<Habit>? habits,
    Map<String, double>? completionRates,
    Map<DateTime, int>? dailyHabitCounts,
    Map<DateTime, Map<String, bool>>? calendarData,
    DateTime? currentMonth,
    bool? isLoading,
    int? periodDays,
    String? filterHabitId,
    bool clearFilter = false,
  }) {
    return StatsState(
      habits: habits ?? this.habits,
      completionRates: completionRates ?? this.completionRates,
      dailyHabitCounts: dailyHabitCounts ?? this.dailyHabitCounts,
      calendarData: calendarData ?? this.calendarData,
      currentMonth: currentMonth ?? this.currentMonth,
      isLoading: isLoading ?? this.isLoading,
      periodDays: periodDays ?? this.periodDays,
      filterHabitId: clearFilter ? null : (filterHabitId ?? this.filterHabitId),
    );
  }

  /// Returns calendarData filtered by the selected habit, or all habits if none selected.
  Map<DateTime, Map<String, bool>> get filteredCalendarData {
    if (filterHabitId == null) return calendarData;
    return calendarData.map((date, habitMap) {
      final filtered = {filterHabitId!: habitMap[filterHabitId] ?? false};
      return MapEntry(date, filtered);
    });
  }
}

class StatsNotifier extends StateNotifier<StatsState> {
  final HabitDao _habitDao;
  final HabitEntryDao _habitEntryDao;

  StatsNotifier(this._habitDao, this._habitEntryDao) : super(StatsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final habits = await _habitDao.getActiveHabits();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final periodStart = today.subtract(Duration(days: state.periodDays - 1));

    // Completion rates for each habit over selected period
    final rates = <String, double>{};
    for (final h in habits) {
      rates[h.id] = await _habitEntryDao.getCompletionRate(h.id, periodStart, today);
    }

    // Daily habit completion counts
    final dailyCounts = await _habitEntryDao.getDailyCompletionCounts(periodStart, today);

    // Calendar data for current month
    final calData = await _loadCalendarData(state.currentMonth, habits);

    state = state.copyWith(
      habits: habits,
      completionRates: rates,
      dailyHabitCounts: dailyCounts,
      calendarData: calData,
      isLoading: false,
    );
  }

  Future<Map<DateTime, Map<String, bool>>> _loadCalendarData(
      DateTime month, List<Habit> habits) async {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    final entries = await _habitEntryDao.getEntriesForRange(firstDay, lastDay);

    final Map<DateTime, Map<String, bool>> data = {};
    for (final entry in entries) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      data.putIfAbsent(date, () => {});
      data[date]![entry.habitId] = entry.completed;
    }
    return data;
  }

  void setPeriod(int days) {
    state = state.copyWith(periodDays: days);
    load();
  }

  void setFilter(String? habitId) {
    if (habitId == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(filterHabitId: habitId);
    }
  }

  void previousMonth() {
    final prev = DateTime(state.currentMonth.year, state.currentMonth.month - 1);
    state = state.copyWith(currentMonth: prev);
    load();
  }

  void nextMonth() {
    final next = DateTime(state.currentMonth.year, state.currentMonth.month + 1);
    state = state.copyWith(currentMonth: next);
    load();
  }
}

final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  return StatsNotifier(
    ref.watch(habitDaoProvider),
    ref.watch(habitEntryDaoProvider),
  );
});
