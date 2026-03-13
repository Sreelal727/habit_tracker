import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'today_notifier.dart';
import '../../config/constants.dart';
import '../../config/theme/app_colors.dart';
import '../../features/coins/coins_notifier.dart';
import '../../features/coins/daily_reward_dialog.dart';
import '../../shared/widgets/add_habit_dialog.dart';
import '../../shared/widgets/add_goal_dialog.dart';
import '../../shared/widgets/percent_slider_dialog.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _hasShownRewardDialog = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(todayProvider);
    final notifier = ref.read(todayProvider.notifier);
    final coinsState = ref.watch(coinsProvider);
    final today = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(today);

    // Show daily reward dialog
    if (!_hasShownRewardDialog &&
        !state.isLoading &&
        !coinsState.isLoading &&
        coinsState.canClaimToday) {
      _hasShownRewardDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const DailyRewardDialog(),
          );
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(dateStr),
        actions: [
          // Coin balance chip
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ActionChip(
              avatar: const Icon(Icons.monetization_on,
                  color: AppColors.secondary, size: 18),
              label: Text(
                '${coinsState.coinBalance}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => context.push('/settings/shop'),
              backgroundColor: AppColors.secondary.withOpacity(0.1),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHabitsCard(context, state, notifier),
                const SizedBox(height: 16),
                _buildDailyGoalsCard(context, state, notifier),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context, notifier),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHabitsCard(
      BuildContext context, TodayState state, TodayNotifier notifier) {
    final totalCount = state.habits.length;
    final totalPercent = totalCount > 0
        ? state.habits.fold<int>(
                0, (sum, h) => sum + state.getHabitPercent(h.id)) /
            totalCount
        : 0.0;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Habits',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold)),
                Text('${totalPercent.round()}% completed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant)),
              ],
            ),
            if (totalCount > 0) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: totalPercent / 100,
                  minHeight: 6,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (state.habits.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No habits yet. Tap + to add one!',
                      style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ),
              )
            else
              ...state.habits.map((habit) {
                final percent = state.getHabitPercent(habit.id);
                final streak = state.streaks[habit.id] ?? 0;
                return _HabitTile(
                  habit: habit,
                  percent: percent,
                  streak: streak,
                  onToggle: () => notifier.toggleHabit(habit.id),
                  onSetPercent: () => _showPercentSlider(
                    context,
                    habit.name,
                    percent,
                    Color(habit.color),
                    (p) => notifier.updateHabitPercent(habit.id, p),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyGoalsCard(
      BuildContext context, TodayState state, TodayNotifier notifier) {
    final totalCount = state.dailyGoals.length;
    final totalPercent = totalCount > 0
        ? state.dailyGoals.fold<int>(
                0, (sum, g) => sum + state.getGoalPercent(g.id)) /
            totalCount
        : 0.0;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Daily Goals',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                if (totalCount > 0)
                  Text('${totalPercent.round()}% completed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant)),
              ],
            ),
            if (totalCount > 0) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: totalPercent / 100,
                  minHeight: 6,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (state.dailyGoals.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No daily goals. Tap + to add one!',
                      style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ),
              )
            else
              ...state.dailyGoals.map((goal) {
                final percent = state.getGoalPercent(goal.id);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Checkbox(
                    value: percent >= 100,
                    onChanged: (_) => notifier.toggleGoal(goal.id),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  title: GestureDetector(
                    onLongPress: () => _showPercentSlider(
                      context,
                      goal.title,
                      percent,
                      null,
                      (p) => notifier.updateGoalPercent(goal.id, p),
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
                              color: colorScheme.primary.withValues(alpha: 0.1),
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
                    onPressed: () => notifier.deleteDailyGoal(goal.id),
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
    Color? color,
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

  void _showAddOptions(BuildContext context, TodayNotifier notifier) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('Add Habit'),
              onTap: () {
                Navigator.pop(context);
                _showAddHabitDialog(context, notifier);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Add Daily Goal'),
              onTap: () {
                Navigator.pop(context);
                _showAddGoalDialog(context, notifier);
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Browse Preset Habits'),
              onTap: () {
                Navigator.pop(context);
                context.push('/presets');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context, TodayNotifier notifier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddHabitDialog(),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        notifier.addHabit(
          result['name'] as String,
          result['icon'] as String,
          result['color'] as int,
        );
      }
    });
  }

  void _showAddGoalDialog(BuildContext context, TodayNotifier notifier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddGoalDialog(),
    ).then((result) {
      if (result != null && result is String) {
        notifier.addDailyGoal(result);
      }
    });
  }
}

class _HabitTile extends StatelessWidget {
  final dynamic habit;
  final int percent;
  final int streak;
  final VoidCallback onToggle;
  final VoidCallback onSetPercent;

  const _HabitTile({
    required this.habit,
    required this.percent,
    required this.streak,
    required this.onToggle,
    required this.onSetPercent,
  });

  String? _getCustomSubtitle() {
    try {
      final customStr = habit.customization as String;
      if (customStr.isEmpty || customStr == '{}') return null;
      final custom = jsonDecode(customStr) as Map<String, dynamic>;
      if (custom.isEmpty) return null;

      final parts = <String>[];
      for (final entry in custom.entries) {
        final val = entry.value;
        if (val is double && val % 1 == 0) {
          parts.add('${val.toInt()}');
        } else {
          parts.add('$val');
        }
      }
      return parts.join(' | ');
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(habit.color);
    final subtitle = _getCustomSubtitle();
    final colorScheme = Theme.of(context).colorScheme;
    final isCompleted = percent >= 100;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isCompleted ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: percent > 0 && !isCompleted
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        value: percent / 100,
                        strokeWidth: 3,
                        backgroundColor: color.withValues(alpha: 0.2),
                        color: color,
                      ),
                    ),
                    Text(
                      '$percent',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                )
              : Icon(
                  isCompleted
                      ? Icons.check
                      : HabitIcons.getIcon(habit.icon),
                  color: isCompleted ? Colors.white : color,
                  size: 22,
                ),
        ),
      ),
      title: GestureDetector(
        onLongPress: onSetPercent,
        child: Text(
          habit.name,
          style: TextStyle(
            color: isCompleted ? colorScheme.onSurfaceVariant : null,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Percent badge for partial completion
          if (percent > 0 && !isCompleted)
            GestureDetector(
              onTap: onSetPercent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ),
          if (streak >= StreakThresholds.fireIcon) ...[
            const Icon(Icons.local_fire_department,
                color: Colors.orange, size: 18),
            const SizedBox(width: 2),
          ],
          if (streak > 0)
            Text('$streak day${streak > 1 ? 's' : ''}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
