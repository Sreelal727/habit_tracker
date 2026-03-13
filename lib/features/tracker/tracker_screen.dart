import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'tracker_notifier.dart';
import '../../config/constants.dart';
import '../../shared/widgets/percent_slider_dialog.dart';

class TrackerScreen extends ConsumerStatefulWidget {
  const TrackerScreen({super.key});

  @override
  ConsumerState<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends ConsumerState<TrackerScreen> {
  String? _filterHabitId; // null = show all

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackerProvider);
    final notifier = ref.read(trackerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tracker')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.habits.isEmpty
              ? Center(
                  child: Text('No habits to track yet.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant)))
              : Column(
                  children: [
                    // Filter chip row
                    _buildFilterRow(state, colorScheme),
                    // Grid
                    Expanded(child: _buildGrid(context, state, notifier)),
                  ],
                ),
    );
  }

  Widget _buildFilterRow(TrackerState state, ColorScheme colorScheme) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: _filterHabitId == null,
              onSelected: (_) => setState(() => _filterHabitId = null),
            ),
          ),
          ...state.habits.map((h) {
            final isSelected = _filterHabitId == h.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Icon(
                  HabitIcons.getIcon(h.icon),
                  size: 14,
                  color: isSelected ? Colors.white : Color(h.color),
                ),
                label: Text(
                  h.name.length > 12 ? '${h.name.substring(0, 11)}…' : h.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                selectedColor: Color(h.color),
                onSelected: (_) => setState(() =>
                    _filterHabitId = isSelected ? null : h.id),
                showCheckmark: false,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGrid(
      BuildContext context, TrackerState state, TrackerNotifier notifier) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dates = List.generate(
      state.daysToShow,
      (i) => today.subtract(Duration(days: state.daysToShow - 1 - i)),
    );
    final colorScheme = Theme.of(context).colorScheme;

    // Filter habits by selected filter
    final visibleHabits = _filterHabitId == null
        ? state.habits
        : state.habits.where((h) => h.id == _filterHabitId).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header row
            Row(
              children: [
                const SizedBox(width: 120),
                ...dates.map((date) {
                  final isFuture = date.isAfter(today);
                  return SizedBox(
                    width: 32,
                    child: Center(
                      child: Text(
                        DateFormat('d').format(date),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _isToday(date)
                              ? Theme.of(context).colorScheme.primary
                              : isFuture
                                  ? colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.4)
                                  : colorScheme.onSurfaceVariant,
                          fontWeight: _isToday(date) ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
            // Month indicator
            Row(
              children: [
                const SizedBox(width: 120),
                ...dates.map((date) => SizedBox(
                      width: 32,
                      child: Center(
                        child: date.day == 1 || date == dates.first
                            ? Text(
                                DateFormat('MMM').format(date),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 9),
                              )
                            : const SizedBox.shrink(),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 8),
            // Habit rows (filtered)
            ...visibleHabits.map((habit) {
              final color = Color(habit.color);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 120,
                      child: Row(
                        children: [
                          Icon(HabitIcons.getIcon(habit.icon),
                              size: 18, color: color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              habit.name,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...dates.map((date) {
                      final isFuture = date.isAfter(today);
                      final percent = state.getPercent(habit.id, date);
                      final completed = percent >= 100;
                      return GestureDetector(
                        onTap: isFuture
                            ? null
                            : () => notifier.toggleEntry(habit.id, date),
                        onLongPress: isFuture
                            ? null
                            : () => _showPercentSlider(
                                  context,
                                  habit.name,
                                  percent,
                                  color,
                                  (p) =>
                                      notifier.updatePercent(habit.id, date, p),
                                ),
                        child: Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isFuture
                                ? colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5)
                                : completed
                                    ? color
                                    : percent > 0
                                        ? color.withValues(
                                            alpha: 0.1 + (percent / 100 * 0.6))
                                        : color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: isFuture
                              ? null
                              : completed
                                  ? const Icon(Icons.check,
                                      size: 14, color: Colors.white)
                                  : percent > 0
                                      ? Center(
                                          child: Text(
                                            '$percent',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: percent > 50
                                                  ? Colors.white
                                                  : color,
                                            ),
                                          ),
                                        )
                                      : null,
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showPercentSlider(
    BuildContext context,
    String title,
    int currentPercent,
    Color color,
    ValueChanged<int> onSave,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PercentSliderDialog(
        title: title,
        initialPercent: currentPercent,
        accentColor: color,
      ),
    ).then((result) {
      if (result != null && result is int) {
        onSave(result);
      }
    });
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
