import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/database/app_database.dart';
import '../../config/constants.dart';
import '../../providers/app_providers.dart';

final _manageHabitsProvider = FutureProvider<List<Habit>>((ref) {
  return ref.watch(habitDaoProvider).getAllHabits();
});

class ManageHabitsScreen extends ConsumerWidget {
  const ManageHabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(_manageHabitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Habits')),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (habits) {
          if (habits.isEmpty) {
            return Center(
                child: Text('No habits yet.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)));
          }

          final activeHabits =
              habits.where((h) => !h.isArchived).toList();
          final archivedHabits =
              habits.where((h) => h.isArchived).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (activeHabits.isNotEmpty) ...[
                Text('Active',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...activeHabits.map((habit) => _HabitManageTile(
                      habit: habit,
                      onArchive: () async {
                        await ref.read(habitDaoProvider).archiveHabit(habit.id);
                        ref.invalidate(_manageHabitsProvider);
                      },
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Habit?'),
                            content: const Text(
                                'This will permanently delete this habit and all its history.'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel')),
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text('Delete',
                                      style: TextStyle(color: Theme.of(context).colorScheme.error))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref
                              .read(habitDaoProvider)
                              .deleteHabit(habit.id);
                          ref.invalidate(_manageHabitsProvider);
                        }
                      },
                    )),
              ],
              if (archivedHabits.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Archived',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                ...archivedHabits.map((habit) => _HabitManageTile(
                      habit: habit,
                      isArchived: true,
                      onRestore: () async {
                        await ref.read(habitDaoProvider).updateHabit(
                              habit.toCompanion(true).copyWith(
                                    isArchived: const Value(false),
                                  ),
                            );
                        ref.invalidate(_manageHabitsProvider);
                      },
                      onDelete: () async {
                        await ref
                            .read(habitDaoProvider)
                            .deleteHabit(habit.id);
                        ref.invalidate(_manageHabitsProvider);
                      },
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HabitManageTile extends StatelessWidget {
  final Habit habit;
  final bool isArchived;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;
  final VoidCallback? onDelete;

  const _HabitManageTile({
    required this.habit,
    this.isArchived = false,
    this.onArchive,
    this.onRestore,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(habit.color);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(HabitIcons.getIcon(habit.icon), color: color, size: 20),
        ),
        title: Text(habit.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isArchived && onArchive != null)
              IconButton(
                icon: const Icon(Icons.archive_outlined, size: 20),
                tooltip: 'Archive',
                onPressed: onArchive,
              ),
            if (isArchived && onRestore != null)
              IconButton(
                icon: const Icon(Icons.unarchive_outlined, size: 20),
                tooltip: 'Restore',
                onPressed: onRestore,
              ),
            if (onDelete != null)
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 20, color: Theme.of(context).colorScheme.error),
                tooltip: 'Delete',
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
