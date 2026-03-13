import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'groups_notifier.dart';
import 'create_group_dialog.dart';
import 'join_group_dialog.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupsProvider);
    final notifier = ref.read(groupsProvider.notifier);

    // Show error snackbar
    ref.listen(groupsProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
        notifier.clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About Groups',
            onPressed: () => _showInfo(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context, ref),
        icon: const Icon(Icons.group_add),
        label: const Text('Add Group'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.groups.isEmpty
              ? _EmptyState(onAdd: () => _showAddOptions(context, ref))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: state.groups.length,
                  itemBuilder: (context, index) {
                    final group = state.groups[index];
                    return _GroupCard(
                      group: group,
                      onTap: () => context.push('/groups/${group.id}'),
                      onLeave: () => _confirmLeave(context, notifier, group.id, group.name),
                    );
                  },
                ),
    );
  }

  void _showAddOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.add)),
              title: const Text('Create a Group'),
              subtitle: const Text('Start a new group and invite friends'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => CreateGroupDialog(
                    onCreated: (groupId) => context.push('/groups/$groupId'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.vpn_key_outlined)),
              title: const Text('Join a Group'),
              subtitle: const Text('Enter an invite code'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => JoinGroupDialog(
                    onJoined: (groupId) => context.push('/groups/$groupId'),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmLeave(BuildContext context, GroupsNotifier notifier,
      String groupId, String groupName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave Group?'),
        content: Text('Are you sure you want to leave "$groupName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              notifier.leaveGroup(groupId);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('How Groups Work'),
        content: const Text(
          '1. Create a group and share the 6-character invite code with friends.\n\n'
          '2. Friends join using your code.\n\n'
          '3. Add shared habits or goals to the group.\n\n'
          '4. Everyone logs their own progress — see how the whole group is doing!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final dynamic group;
  final VoidCallback onTap;
  final VoidCallback onLeave;

  const _GroupCard({
    required this.group,
    required this.onTap,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final memberCount = (group.members as Map).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  group.name.isNotEmpty
                      ? group.name[0].toUpperCase()
                      : 'G',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people_outline,
                            size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '$memberCount member${memberCount == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.vpn_key_outlined,
                            size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          group.inviteCode,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'leave') onLeave();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'leave',
                    child: Row(
                      children: [
                        Icon(Icons.exit_to_app, size: 18),
                        SizedBox(width: 8),
                        Text('Leave Group'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 80, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'No Groups Yet',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a group to share habits and goals with friends, and see each other\'s progress!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.group_add),
              label: const Text('Create or Join a Group'),
            ),
          ],
        ),
      ),
    );
  }
}
