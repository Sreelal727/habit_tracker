import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'goals_notifier.dart';
import '../../shared/widgets/add_goal_dialog.dart';
import '../../shared/widgets/percent_slider_dialog.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Goals'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Weekly'),
              Tab(text: 'Yearly'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _WeeklyGoalsTab(),
            _YearlyGoalsTab(),
          ],
        ),
      ),
    );
  }
}

void _showPercentSlider(
  BuildContext context,
  String title,
  int currentPercent,
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
    ),
  ).then((result) {
    if (result != null && result is int) {
      onSave(result);
    }
  });
}

class _WeeklyGoalsTab extends ConsumerWidget {
  const _WeeklyGoalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(goalsProvider);
    final notifier = ref.read(goalsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    final weekStart = state.currentWeekStart;
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekLabel =
        '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekEnd)}';

    final totalCount = state.weeklyGoals.length;
    final totalPercent = totalCount > 0
        ? state.weeklyGoals.fold<int>(
                0, (sum, g) => sum + state.getWeeklyGoalPercent(g.id)) /
            totalCount
        : 0.0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: notifier.previousWeek,
              ),
              Text(weekLabel,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: notifier.nextWeek,
              ),
            ],
          ),
        ),
        if (totalCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalPercent / 100,
                      minHeight: 6,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${totalPercent.round()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Expanded(
          child: state.weeklyGoals.isEmpty
              ? Center(
                  child: Text('No weekly goals yet.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.weeklyGoals.length,
                  itemBuilder: (context, index) {
                    final goal = state.weeklyGoals[index];
                    final percent = state.getWeeklyGoalPercent(goal.id);
                    return ListTile(
                      leading: Checkbox(
                        value: percent >= 100,
                        onChanged: (_) => notifier.toggleWeeklyGoal(goal.id),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      title: GestureDetector(
                        onLongPress: () => _showPercentSlider(
                          context,
                          goal.title,
                          percent,
                          (p) => notifier.updateWeeklyGoalPercent(goal.id, p),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                goal.title,
                                style: TextStyle(
                                  color: percent >= 100
                                      ? colorScheme.onSurfaceVariant
                                      : null,
                                ),
                              ),
                            ),
                            if (percent > 0 && percent < 100)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$percent%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => notifier.deleteGoal(goal.id),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddGoalDialog(context, notifier, 'weekly'),
              icon: const Icon(Icons.add),
              label: const Text('Add Weekly Goal'),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddGoalDialog(
      BuildContext context, GoalsNotifier notifier, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddGoalDialog(goalType: type),
    ).then((result) {
      if (result != null && result is String) {
        notifier.addGoal(result, type);
      }
    });
  }
}

class _YearlyGoalsTab extends ConsumerWidget {
  const _YearlyGoalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(goalsProvider);
    final notifier = ref.read(goalsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final year = DateTime.now().year;

    final totalCount = state.yearlyGoals.length;
    final totalPercent = totalCount > 0
        ? state.yearlyGoals.fold<int>(
                0, (sum, g) => sum + state.getYearlyGoalPercent(g.id)) /
            totalCount
        : 0.0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('$year',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        if (totalCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalPercent / 100,
                      minHeight: 6,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${totalPercent.round()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Expanded(
          child: state.yearlyGoals.isEmpty
              ? Center(
                  child: Text('No yearly goals yet.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.yearlyGoals.length,
                  itemBuilder: (context, index) {
                    final goal = state.yearlyGoals[index];
                    final percent = state.getYearlyGoalPercent(goal.id);
                    return ListTile(
                      leading: Checkbox(
                        value: percent >= 100,
                        onChanged: (_) => notifier.toggleYearlyGoal(goal.id),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      title: GestureDetector(
                        onLongPress: () => _showPercentSlider(
                          context,
                          goal.title,
                          percent,
                          (p) => notifier.updateYearlyGoalPercent(goal.id, p),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                goal.title,
                                style: TextStyle(
                                  color: percent >= 100
                                      ? colorScheme.onSurfaceVariant
                                      : null,
                                ),
                              ),
                            ),
                            if (percent > 0 && percent < 100)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$percent%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => notifier.deleteGoal(goal.id),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddGoalDialog(context, notifier, 'yearly'),
              icon: const Icon(Icons.add),
              label: const Text('Add Yearly Goal'),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddGoalDialog(
      BuildContext context, GoalsNotifier notifier, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddGoalDialog(goalType: type),
    ).then((result) {
      if (result != null && result is String) {
        notifier.addGoal(result, type);
      }
    });
  }
}
