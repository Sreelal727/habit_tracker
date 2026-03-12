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

    final weekStart = state.currentWeekStart;
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekLabel =
        '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekEnd)}';

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
        Expanded(
          child: state.weeklyGoals.isEmpty
              ? const Center(
                  child: Text('No weekly goals yet.',
                      style: TextStyle(color: Colors.grey)))
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
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted ? Colors.grey : null,
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
    final year = DateTime.now().year;

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
        Expanded(
          child: state.yearlyGoals.isEmpty
              ? const Center(
                  child: Text('No yearly goals yet.',
                      style: TextStyle(color: Colors.grey)))
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
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted ? Colors.grey : null,
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
