import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'group_detail_notifier.dart';
import 'group_model.dart';
import '../../config/constants.dart';
import '../../shared/widgets/percent_slider_dialog.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupDetailProvider(groupId));
    final notifier = ref.read(groupDetailProvider(groupId).notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    ref.listen(groupDetailProvider(groupId), (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
        notifier.clearError();
      }
    });

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final group = state.group;
    if (group == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Group not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Copy invite code',
            onPressed: () => _copyCode(context, group.inviteCode),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemSheet(context, notifier, state),
        icon: const Icon(Icons.add),
        label: const Text('Add Habit/Goal'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Invite code card
          _InviteCodeCard(code: group.inviteCode, onCopy: () => _copyCode(context, group.inviteCode)),
          const SizedBox(height: 16),

          // Members section
          _SectionHeader(title: 'Members (${group.members.length})'),
          const SizedBox(height: 8),
          _MembersRow(members: group.members, currentUid: currentUid),
          const SizedBox(height: 20),

          // Shared habits/goals
          _SectionHeader(title: "Today's Progress"),
          const SizedBox(height: 8),

          if (state.items.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.add_task, size: 48, color: colorScheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(
                      'No shared habits yet.\nTap + to add a habit or goal for the group.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...state.items.map((item) => _GroupItemCard(
                  item: item,
                  todayProgress: state.todayProgress[item.id] ?? {},
                  members: group.members,
                  currentUid: currentUid,
                  myPercent: notifier.myPercent(item.id),
                  onUpdateProgress: (percent) =>
                      notifier.updateProgress(item.id, percent),
                  onRemove: () => notifier.removeItem(item.id),
                )),
        ],
      ),
    );
  }

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invite code "$code" copied to clipboard!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddItemSheet(
      BuildContext context, GroupDetailNotifier notifier, GroupDetailState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddItemSheet(notifier: notifier),
    );
  }
}

// ─── Sub-widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  final String code;
  final VoidCallback onCopy;

  const _InviteCodeCard({required this.code, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.vpn_key, color: colorScheme.onPrimaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invite Code',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                  ),
                  Text(
                    code,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.copy, color: colorScheme.onPrimaryContainer),
              onPressed: onCopy,
              tooltip: 'Copy code',
            ),
          ],
        ),
      ),
    );
  }
}

class _MembersRow extends StatelessWidget {
  final Map<String, String> members;
  final String currentUid;

  const _MembersRow({required this.members, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 72,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: members.entries.map((entry) {
          final isMe = entry.key == currentUid;
          final name = entry.value;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: isMe
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isMe
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMe ? 'You' : (name.length > 8 ? '${name.substring(0, 7)}…' : name),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GroupItemCard extends StatelessWidget {
  final GroupItem item;
  final Map<String, GroupProgress> todayProgress; // uid → progress
  final Map<String, String> members; // uid → name
  final String currentUid;
  final int myPercent;
  final ValueChanged<int> onUpdateProgress;
  final VoidCallback onRemove;

  const _GroupItemCard({
    required this.item,
    required this.todayProgress,
    required this.members,
    required this.currentUid,
    required this.myPercent,
    required this.onUpdateProgress,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(item.color);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(HabitIcons.getIcon(item.icon), color: color, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        item.type == 'habit' ? 'Daily Habit' : 'Goal',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: color,
                            ),
                      ),
                    ],
                  ),
                ),
                // My progress badge + update button
                GestureDetector(
                  onTap: () => _showSlider(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: myPercent >= 100
                          ? color
                          : myPercent > 0
                              ? color.withValues(alpha: 0.15)
                              : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          myPercent >= 100 ? Icons.check : Icons.edit_outlined,
                          size: 14,
                          color: myPercent >= 100
                              ? Colors.white
                              : myPercent > 0
                                  ? color
                                  : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          myPercent >= 100 ? 'Done' : '$myPercent%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: myPercent >= 100
                                ? Colors.white
                                : myPercent > 0
                                    ? color
                                    : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'remove') onRemove();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Remove'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Member progress rows
            ...members.entries.map((entry) {
              final uid = entry.key;
              final name = uid == currentUid ? 'You' : entry.value;
              final progress = todayProgress[uid];
              final pct = progress?.completionPercent ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: uid == currentUid
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: uid == currentUid
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 56,
                      child: Text(
                        name.length > 7 ? '${name.substring(0, 6)}…' : name,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          minHeight: 8,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            pct >= 100
                                ? color
                                : color.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '$pct%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: pct > 0 ? color : colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showSlider(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PercentSliderDialog(
        title: item.title,
        initialPercent: myPercent,
        accentColor: Color(item.color),
      ),
    ).then((result) {
      if (result != null && result is int) {
        onUpdateProgress(result);
      }
    });
  }
}

// ─── Add Item Sheet ──────────────────────────────────────────────────────────

class _AddItemSheet extends ConsumerStatefulWidget {
  final GroupDetailNotifier notifier;

  const _AddItemSheet({required this.notifier});

  @override
  ConsumerState<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<_AddItemSheet> {
  final _titleController = TextEditingController();
  String _type = 'habit';
  String _selectedIcon = 'star';
  int _selectedColor = 0xFF4CAF50;
  bool _isSaving = false;

  final _icons = [
    'fitness', 'water_drop', 'book', 'bed', 'run', 'meditation',
    'food', 'money', 'clean', 'learn', 'star', 'heart',
  ];

  final _colors = [
    0xFF4CAF50, 0xFF2196F3, 0xFFFF9800, 0xFFE91E63,
    0xFF9C27B0, 0xFF00BCD4, 0xFFFF5722, 0xFF607D8B,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add to Group',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Type toggle
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'habit', label: Text('Habit'), icon: Icon(Icons.repeat)),
                ButtonSegment(value: 'goal', label: Text('Goal'), icon: Icon(Icons.flag_outlined)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: _type == 'habit' ? 'Habit name' : 'Goal title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Icon picker
            Text('Icon', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _icons.map((icon) {
                  final isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(_selectedColor)
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        HabitIcons.getIcon(icon),
                        size: 20,
                        color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Color picker
            Text('Color', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _colors.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Color(color),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: colorScheme.outline, width: 2)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Add to Group'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    await widget.notifier.addItem(
      type: _type,
      title: title,
      icon: _selectedIcon,
      color: _selectedColor,
    );
    if (mounted) Navigator.pop(context);
  }
}
