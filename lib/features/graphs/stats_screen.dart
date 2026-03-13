import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'stats_notifier.dart';
import '../../config/constants.dart';
import '../../core/database/app_database.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statsProvider);
    final notifier = ref.read(statsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.hub_outlined), text: 'Web'),
            Tab(icon: Icon(Icons.bar_chart_outlined), text: 'Bar'),
            Tab(icon: Icon(Icons.calendar_month_outlined), text: 'Calendar'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _RadarTab(state: state, notifier: notifier),
                _BarTab(state: state, notifier: notifier),
                _CalendarTab(state: state, notifier: notifier),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────
// Tab 1: Radar / Spider Web
// ─────────────────────────────────────────────

class _RadarTab extends StatelessWidget {
  final StatsState state;
  final StatsNotifier notifier;

  const _RadarTab({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    if (state.habits.isEmpty) {
      return const Center(child: Text('No habits yet. Add some habits to see your web!'));
    }

    final avg = state.completionRates.values.isEmpty
        ? 0.0
        : state.completionRates.values.reduce((a, b) => a + b) /
            state.completionRates.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Period selector
        _PeriodSelector(current: state.periodDays, onSelect: notifier.setPeriod),
        const SizedBox(height: 16),

        // Radar card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Performance Web',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Last ${state.periodDays} days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 320,
                  child: _RadarWebChart(
                    habits: state.habits,
                    completionRates: state.completionRates,
                    avgPercent: avg,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Legend
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Habits',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...state.habits.map((h) {
                  final pct = ((state.completionRates[h.id] ?? 0) * 100).round();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(h.color),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(HabitIcons.getIcon(h.icon),
                            size: 16, color: Color(h.color)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(h.name,
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                        Text(
                          '$pct%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Color(h.color),
                              ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RadarWebChart extends StatelessWidget {
  final List<Habit> habits;
  final Map<String, double> completionRates;
  final double avgPercent;

  const _RadarWebChart({
    required this.habits,
    required this.completionRates,
    required this.avgPercent,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RadarPainter(
        habits: habits,
        completionRates: completionRates,
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${(avgPercent * 100).round()}%',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            Text(
              'avg',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<Habit> habits;
  final Map<String, double> completionRates;
  final bool isDark;

  _RadarPainter({
    required this.habits,
    required this.completionRates,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (habits.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2 - 36;
    final n = habits.length;
    final angleStep = (2 * math.pi) / n;
    // Start from top (-π/2)
    const startAngle = -math.pi / 2;

    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw concentric web rings at 25%, 50%, 75%, 100%
    for (int ring = 1; ring <= 4; ring++) {
      final r = maxRadius * ring / 4;
      final path = Path();
      for (int i = 0; i < n; i++) {
        final angle = startAngle + i * angleStep;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);

      // Label ring %
      if (ring < 4) {
        final labelOffset = Offset(
          center.dx + 4,
          center.dy - r + 2,
        );
        final tp = TextPainter(
          text: TextSpan(
            text: '${ring * 25}%',
            style: TextStyle(
              fontSize: 8,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.35),
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        tp.paint(canvas, labelOffset);
      }
    }

    // Draw spokes
    final spokePaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int i = 0; i < n; i++) {
      final angle = startAngle + i * angleStep;
      final x = center.dx + maxRadius * math.cos(angle);
      final y = center.dy + maxRadius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), spokePaint);
    }

    // Compute data polygon points
    final dataPoints = <Offset>[];
    for (int i = 0; i < n; i++) {
      final rate = completionRates[habits[i].id] ?? 0.0;
      final r = maxRadius * rate.clamp(0.0, 1.0);
      final angle = startAngle + i * angleStep;
      dataPoints.add(Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      ));
    }

    // Fill polygon with gradient-ish overlay using habit colors blended
    if (dataPoints.isNotEmpty) {
      // Use primary habit color or blend — simplify: use first habit color with low alpha
      final fillColor =
          Color(habits[0].color).withValues(alpha: 0.18);
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;

      final strokePaint = Paint()
        ..color = Color(habits[0].color).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round;

      final dataPath = Path();
      for (int i = 0; i < dataPoints.length; i++) {
        if (i == 0) {
          dataPath.moveTo(dataPoints[i].dx, dataPoints[i].dy);
        } else {
          dataPath.lineTo(dataPoints[i].dx, dataPoints[i].dy);
        }
      }
      dataPath.close();
      canvas.drawPath(dataPath, fillPaint);
      canvas.drawPath(dataPath, strokePaint);

      // Draw dots at each vertex
      for (int i = 0; i < dataPoints.length; i++) {
        final dotPaint = Paint()
          ..color = Color(habits[i].color)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(dataPoints[i], 4, dotPaint);
      }
    }

    // Draw habit labels at spoke tips
    for (int i = 0; i < n; i++) {
      final angle = startAngle + i * angleStep;
      final labelR = maxRadius + 24;
      final x = center.dx + labelR * math.cos(angle);
      final y = center.dy + labelR * math.sin(angle);

      // Short label (icon not possible in CustomPainter, use first 3 chars)
      final label = habits[i].name.length > 6
          ? '${habits[i].name.substring(0, 5)}…'
          : habits[i].name;

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Color(habits[i].color),
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 52);

      tp.paint(
        canvas,
        Offset(x - tp.width / 2, y - tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.habits != habits ||
      old.completionRates != completionRates ||
      old.isDark != isDark;
}

// ─────────────────────────────────────────────
// Tab 2: Bar Chart
// ─────────────────────────────────────────────

class _BarTab extends StatelessWidget {
  final StatsState state;
  final StatsNotifier notifier;

  const _BarTab({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    if (state.habits.isEmpty) {
      return const Center(child: Text('No habits yet.'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PeriodSelector(current: state.periodDays, onSelect: notifier.setPeriod),
        const SizedBox(height: 16),
        _buildCompletionChart(context, state),
        const SizedBox(height: 24),
        _buildDailyHitsChart(context, state),
      ],
    );
  }

  Widget _buildCompletionChart(BuildContext context, StatsState state) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Completion Rate (${state.periodDays} days)',
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
                          const TextStyle(color: Colors.white, fontSize: 12),
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
                          if (index >= state.habits.length) return const SizedBox.shrink();
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
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: state.habits.asMap().entries.map((entry) {
                    final rate = (state.completionRates[entry.value.id] ?? 0) * 100;
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
    for (int i = 0; i < state.periodDays; i++) {
      final date = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: state.periodDays - 1 - i));
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
                              .subtract(Duration(days: state.periodDays - 1 - spot.x.toInt()));
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
                        interval: (state.periodDays / 5).roundToDouble(),
                        getTitlesWidget: (value, meta) {
                          final date = DateTime(now.year, now.month, now.day)
                              .subtract(Duration(days: state.periodDays - 1 - value.toInt()));
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
                          if (value != value.roundToDouble()) return const SizedBox.shrink();
                          return Text('${value.toInt()}',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: colorScheme.onSurfaceVariant));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: colorScheme.primary,
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colorScheme.primary.withValues(alpha: 0.1),
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
}

// ─────────────────────────────────────────────
// Tab 3: Calendar with Filter
// ─────────────────────────────────────────────

class _CalendarTab extends StatelessWidget {
  final StatsState state;
  final StatsNotifier notifier;

  const _CalendarTab({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Filter chips
        if (state.habits.isNotEmpty) ...[
          _HabitFilterChips(
            habits: state.habits,
            selectedId: state.filterHabitId,
            onSelect: notifier.setFilter,
          ),
          const SizedBox(height: 12),
        ],
        _buildCalendar(context, state, notifier),
      ],
    );
  }

  Widget _buildCalendar(BuildContext context, StatsState state, StatsNotifier notifier) {
    final month = state.currentMonth;
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startWeekday = firstDay.weekday;
    final daysInMonth = lastDay.day;
    final colorScheme = Theme.of(context).colorScheme;
    final calData = state.filteredCalendarData;
    final filteredHabit = state.filterHabitId != null
        ? state.habits.where((h) => h.id == state.filterHabitId).firstOrNull
        : null;

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
            ...List.generate(6, (week) {
              return Row(
                children: List.generate(7, (weekday) {
                  final dayIndex = week * 7 + weekday - (startWeekday - 1) + 1;
                  if (dayIndex < 1 || dayIndex > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 44));
                  }

                  final date = DateTime(month.year, month.month, dayIndex);
                  final dayData = calData[date] ?? {};

                  bool isDayComplete;
                  List<String> completedHabitIds;

                  if (state.filterHabitId != null) {
                    // Single habit filter: check if that habit is done
                    isDayComplete = dayData[state.filterHabitId] == true;
                    completedHabitIds = isDayComplete ? [state.filterHabitId!] : [];
                  } else {
                    completedHabitIds = dayData.entries
                        .where((e) => e.value)
                        .map((e) => e.key)
                        .toList();
                    isDayComplete = completedHabitIds.length == state.habits.length &&
                        state.habits.isNotEmpty;
                  }

                  final isToday = _isToday(date);
                  final highlightColor = filteredHabit != null
                      ? Color(filteredHabit.color)
                      : colorScheme.primary;

                  return Expanded(
                    child: Container(
                      height: 44,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: isToday
                            ? Border.all(color: colorScheme.primary, width: 2)
                            : null,
                        color: isDayComplete
                            ? highlightColor.withValues(alpha: 0.15)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$dayIndex',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isToday ? FontWeight.bold : null,
                              )),
                          if (state.filterHabitId == null && completedHabitIds.isNotEmpty)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: completedHabitIds.take(4).map((hId) {
                                final habit = state.habits
                                    .where((h) => h.id == hId)
                                    .firstOrNull;
                                return Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: habit != null
                                        ? Color(habit.color)
                                        : colorScheme.onSurfaceVariant,
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }).toList(),
                            )
                          else if (state.filterHabitId != null && isDayComplete)
                            Icon(Icons.check, size: 12,
                                color: highlightColor),
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

// ─────────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  final int current;
  final void Function(int) onSelect;

  const _PeriodSelector({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [7, 30, 90].map((days) {
        final isSelected = current == days;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text('${days}d'),
            selected: isSelected,
            onSelected: (_) => onSelect(days),
          ),
        );
      }).toList(),
    );
  }
}

class _HabitFilterChips extends StatelessWidget {
  final List<Habit> habits;
  final String? selectedId;
  final void Function(String?) onSelect;

  const _HabitFilterChips({
    required this.habits,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: selectedId == null,
              onSelected: (_) => onSelect(null),
            ),
          ),
          // One chip per habit
          ...habits.map((h) {
            final isSelected = selectedId == h.id;
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
                onSelected: (_) => onSelect(isSelected ? null : h.id),
                showCheckmark: false,
              ),
            );
          }),
        ],
      ),
    );
  }
}
