import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'goals_notifier.dart';
import '../../shared/widgets/add_goal_dialog.dart';

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

    final completedCount =
        state.weeklyGoals.where((g) => state.isWeeklyGoalCompleted(g.id)).length;
    final totalCount = state.weeklyGoals.length;
    final percentage = totalCount > 0
        ? (completedCount / totalCount * 100).round()
        : 0;

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
                      value: completedCount / totalCount,
                      minHeight: 6,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('$percentage%',
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
                    final isCompleted = state.isWeeklyGoalCompleted(goal.id);
                    return ListTile(
                      leading: Checkbox(
                        value: isCompleted,
                        onChanged: (_) => notifier.toggleWeeklyGoal(goal.id),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      title: Text(
                        goal.title,
                        style: TextStyle(
                          color: isCompleted
                              ? colorScheme.onSurfaceVariant
                              : null,
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

    final completedCount =
        state.yearlyGoals.where((g) => state.isYearlyGoalCompleted(g.id)).length;
    final totalCount = state.yearlyGoals.length;
    final percentage = totalCount > 0
        ? (completedCount / totalCount * 100).round()
        : 0;

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
                      value: completedCount / totalCount,
                      minHeight: 6,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('$percentage%',
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
                    final isCompleted = state.isYearlyGoalCompleted(goal.id);
                    return ListTile(
                      leading: Checkbox(
                        value: isCompleted,
                        onChanged: (_) => notifier.toggleYearlyGoal(goal.id),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      title: Text(
                        goal.title,
                        style: TextStyle(
                          color: isCompleted
                              ? colorScheme.onSurfaceVariant
                              : null,
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
