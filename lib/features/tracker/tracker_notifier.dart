import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/habit_dao.dart';
import '../../core/database/daos/habit_entry_dao.dart';
import '../../providers/app_providers.dart';

const _uuid = Uuid();

class TrackerState {
  final List<Habit> habits;
  final Map<String, Map<DateTime, bool>> entries; // habitId -> date -> completed
  final Map<String, Map<DateTime, int>> percents; // habitId -> date -> percent
  final int daysToShow;
  final bool isLoading;

  const TrackerState({
    this.habits = const [],
    this.entries = const {},
    this.percents = const {},
    this.daysToShow = 30,
    this.isLoading = true,
  });

  TrackerState copyWith({
    List<Habit>? habits,
    Map<String, Map<DateTime, bool>>? entries,
    Map<String, Map<DateTime, int>>? percents,
    int? daysToShow,
    bool? isLoading,
  }) {
    return TrackerState(
      habits: habits ?? this.habits,
      entries: entries ?? this.entries,
      percents: percents ?? this.percents,
      daysToShow: daysToShow ?? this.daysToShow,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool isCompleted(String habitId, DateTime date) {
    return entries[habitId]?[DateTime(date.year, date.month, date.day)] ?? false;
  }

  int getPercent(String habitId, DateTime date) {
    return percents[habitId]?[DateTime(date.year, date.month, date.day)] ?? 0;
  }
}

class TrackerNotifier extends StateNotifier<TrackerState> {
  final HabitDao _habitDao;
  final HabitEntryDao _habitEntryDao;

  TrackerNotifier(this._habitDao, this._habitEntryDao)
      : super(const TrackerState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final habits = await _habitDao.getActiveHabits();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: state.daysToShow - 1));
    final end = DateTime(now.year, now.month, now.day);

    final allEntries = await _habitEntryDao.getEntriesForRange(start, end);

    final Map<String, Map<DateTime, bool>> entriesMap = {};
    final Map<String, Map<DateTime, int>> percentsMap = {};
    for (final entry in allEntries) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      entriesMap.putIfAbsent(entry.habitId, () => {});
      entriesMap[entry.habitId]![date] = entry.completed;
      percentsMap.putIfAbsent(entry.habitId, () => {});
      percentsMap[entry.habitId]![date] = entry.completionPercent;
    }

    state = state.copyWith(
      habits: habits,
      entries: entriesMap,
      percents: percentsMap,
      isLoading: false,
    );
  }

  Future<void> toggleEntry(String habitId, DateTime date) async {
    await _habitEntryDao.toggleEntry(_uuid.v4(), habitId, date);
    await load();
  }

  Future<void> updatePercent(String habitId, DateTime date, int percent) async {
    await _habitEntryDao.updateCompletionPercent(
        _uuid.v4(), habitId, date, percent);
    await load();
  }
}

final trackerProvider =
    StateNotifierProvider<TrackerNotifier, TrackerState>((ref) {
  return TrackerNotifier(
    ref.watch(habitDaoProvider),
    ref.watch(habitEntryDaoProvider),
  );
});
