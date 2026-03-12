import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'tracker_notifier.dart';
import '../../config/constants.dart';

class TrackerScreen extends ConsumerWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trackerProvider);
    final notifier = ref.read(trackerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Tracker')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.habits.isEmpty
              ? const Center(
                  child: Text('No habits to track yet.',
                      style: TextStyle(color: Colors.grey)))
              : _buildGrid(context, state, notifier),
    );
  }

  Widget _buildGrid(
      BuildContext context, TrackerState state, TrackerNotifier notifier) {
    final now = DateTime.now();
    final dates = List.generate(
      state.daysToShow,
      (i) => DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: state.daysToShow - 1 - i)),
    );

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
                ...dates.map((date) => SizedBox(
                      width: 32,
                      child: Center(
                        child: Text(
                          DateFormat('d').format(date),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _isToday(date)
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            fontWeight: _isToday(date) ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                    )),
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
                                    ?.copyWith(color: Colors.grey, fontSize: 9),
                              )
                            : const SizedBox.shrink(),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 8),
            // Habit rows
            ...state.habits.map((habit) {
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
                      final completed = state.isCompleted(habit.id, date);
                      return GestureDetector(
                        onTap: () => notifier.toggleEntry(habit.id, date),
                        child: Container(
                          width: 28,
                          height: 28,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: completed
                                ? color
                                : color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: completed
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
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

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
