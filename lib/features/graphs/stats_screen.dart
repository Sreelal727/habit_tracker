import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'stats_notifier.dart';
import '../../config/constants.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(statsProvider);
    final notifier = ref.read(statsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCompletionChart(context, state),
                const SizedBox(height: 24),
                _buildDailyHitsChart(context, state),
                const SizedBox(height: 24),
                _buildCalendar(context, state, notifier),
              ],
            ),
    );
  }

  Widget _buildCompletionChart(BuildContext context, StatsState state) {
    if (state.habits.isEmpty) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Completion Rate (30 days)',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final habit = state.habits[groupIndex];
                        return BarTooltipItem(
                          '${habit.name}\n${rod.toY.toInt()}%',
                          const TextStyle(
                              color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= state.habits.length) {
                            return const SizedBox.shrink();
                          }
                          final habit = state.habits[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(
                              HabitIcons.getIcon(habit.icon),
                              size: 16,
                              color: Color(habit.color),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value % 25 != 0) return const SizedBox.shrink();
                          return Text('${value.toInt()}%',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: colorScheme.onSurfaceVariant));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: state.habits.asMap().entries.map((entry) {
                    final rate =
                        (state.completionRates[entry.value.id] ?? 0) * 100;
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: rate,
                          color: Color(entry.value.color),
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyHitsChart(BuildContext context, StatsState state) {
    final now = DateTime.now();
    final spots = <FlSpot>[];
    for (int i = 0; i < 30; i++) {
      final date = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 29 - i));
      final count = state.dailyHabitCounts[date] ?? 0;
      spots.add(FlSpot(i.toDouble(), count.toDouble()));
    }
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Habits Completed Per Day',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final date = DateTime(now.year, now.month, now.day)
                              .subtract(Duration(days: 29 - spot.x.toInt()));
                          return LineTooltipItem(
                            '${DateFormat('MMM d').format(date)}\n${spot.y.toInt()} habits',
                            const TextStyle(color: Colors.white, fontSize: 11),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 7,
                        getTitlesWidget: (value, meta) {
                          final date =
                              DateTime(now.year, now.month, now.day)
                                  .subtract(
                                      Duration(days: 29 - value.toInt()));
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(DateFormat('d').format(date),
                                style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.onSurfaceVariant)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 25,
                        getTitlesWidget: (value, meta) {
                          if (value != value.roundToDouble()) {
                            return const SizedBox.shrink();
                          }
                          return Text('${value.toInt()}',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: colorScheme.onSurfaceVariant));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  minY: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(
      BuildContext context, StatsState state, StatsNotifier notifier) {
    final month = state.currentMonth;
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startWeekday = firstDay.weekday; // 1=Mon
    final daysInMonth = lastDay.day;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: notifier.previousMonth),
                Text(DateFormat('MMMM yyyy').format(month),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: notifier.nextMonth),
              ],
            ),
            const SizedBox(height: 8),
            // Weekday headers
            Row(
              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(d,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 4),
            // Day grid
            ...List.generate(6, (week) {
              return Row(
                children: List.generate(7, (weekday) {
                  final dayIndex =
                      week * 7 + weekday - (startWeekday - 1) + 1;
                  if (dayIndex < 1 || dayIndex > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 44));
                  }

                  final date = DateTime(month.year, month.month, dayIndex);
                  final dayData = state.calendarData[date] ?? {};
                  final completedHabits = dayData.entries
                      .where((e) => e.value)
                      .map((e) => e.key)
                      .toList();

                  final isToday = _isToday(date);

                  return Expanded(
                    child: Container(
                      height: 44,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: isToday
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2)
                            : null,
                        color: completedHabits.length == state.habits.length &&
                                state.habits.isNotEmpty
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$dayIndex',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    isToday ? FontWeight.bold : null,
                              )),
                          if (completedHabits.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: completedHabits.take(4).map((hId) {
                                final habit = state.habits
                                    .where((h) => h.id == hId)
                                    .firstOrNull;
                                return Container(
                                  width: 6,
                                  height: 6,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: habit != null
                                        ? Color(habit.color)
                                        : colorScheme.onSurfaceVariant,
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
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
