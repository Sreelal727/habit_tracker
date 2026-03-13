import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    final currentUid = Supabase.instance.client.auth.currentUser?.id ?? '';

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
          _InviteCodeCard(
              code: group.inviteCode,
              onCopy: () => _copyCode(context, group.inviteCode)),
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
                    Icon(Icons.add_task,
                        size: 48, color: colorScheme.onSurfaceVariant),
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
                  todayProgress: state.progress[item.id] ?? {},
                  members: group.members,
                  currentUid: currentUid,
                  myPercent: notifier.myPercent(item.id),
                  myProof: notifier.myProof(item.id),
                  pendingProofs: state.pendingProofs[item.id] ?? [],
                  onUpdateProgress: (percent) =>
                      notifier.updateProgress(item.id, percent),
                  onSubmitProof: ({
                    required String proofType,
                    String? caption,
                    double? numericValue,
                    String? numericUnit,
                  }) =>
                      notifier.submitProof(
                    itemId: item.id,
                    proofType: proofType,
                    caption: caption,
                    numericValue: numericValue,
                    numericUnit: numericUnit,
                  ),
                  onVoteProof: (proofId, approve) =>
                      notifier.voteOnProof(proofId, approve),
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

  void _showAddItemSheet(BuildContext context, GroupDetailNotifier notifier,
      GroupDetailState state) {
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
                          color: colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.7),
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
  final List<GroupMember> members;
  final String currentUid;

  const _MembersRow({required this.members, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 72,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: members.map((member) {
          final isMe = member.userId == currentUid;
          final name = member.displayName;
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
                  backgroundImage: member.avatarUrl != null
                      ? NetworkImage(member.avatarUrl!)
                      : null,
                  child: member.avatarUrl == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isMe
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  isMe
                      ? 'You'
                      : (name.length > 8
                          ? '${name.substring(0, 7)}...'
                          : name),
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
  final Map<String, GroupProgress> todayProgress; // userId -> progress
  final List<GroupMember> members;
  final String currentUid;
  final int myPercent;
  final ProofSubmission? myProof;
  final List<ProofSubmission> pendingProofs;
  final ValueChanged<int> onUpdateProgress;
  final Future<void> Function({
    required String proofType,
    String? caption,
    double? numericValue,
    String? numericUnit,
  }) onSubmitProof;
  final void Function(String proofId, bool approve) onVoteProof;
  final VoidCallback onRemove;

  const _GroupItemCard({
    required this.item,
    required this.todayProgress,
    required this.members,
    required this.currentUid,
    required this.myPercent,
    required this.myProof,
    required this.pendingProofs,
    required this.onUpdateProgress,
    required this.onSubmitProof,
    required this.onVoteProof,
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
                  child: Icon(HabitIcons.getIcon(item.icon),
                      color: color, size: 22),
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
                      Row(
                        children: [
                          Text(
                            item.type == 'habit' ? 'Daily Habit' : 'Goal',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: color),
                          ),
                          if (item.requiresProof) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.verified_outlined,
                                size: 12, color: color),
                            const SizedBox(width: 2),
                            Text(
                              'Proof',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Action button: either proof or slider
                if (item.requiresProof)
                  _ProofActionButton(
                    item: item,
                    myProof: myProof,
                    myPercent: myPercent,
                    color: color,
                    colorScheme: colorScheme,
                    onSubmitProof: onSubmitProof,
                  )
                else
                  GestureDetector(
                    onTap: () => _showSlider(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
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
                            myPercent >= 100
                                ? Icons.check
                                : Icons.edit_outlined,
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
            ...members.map((member) {
              final uid = member.userId;
              final name = uid == currentUid ? 'You' : member.displayName;
              final progress = todayProgress[uid];
              final pct = progress?.completionPercent ?? 0;

              // Find proof status for this member on this item
              final memberProof = pendingProofs
                  .where((p) => p.userId == uid)
                  .toList();
              final proofStatus = myProof != null && uid == currentUid
                  ? myProof!.status
                  : memberProof.isNotEmpty
                      ? memberProof.first.status
                      : null;

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
                        name.length > 7 ? '${name.substring(0, 6)}...' : name,
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
                    // Proof status badge or percentage
                    if (item.requiresProof && proofStatus != null)
                      _ProofStatusBadge(status: proofStatus)
                    else
                      SizedBox(
                        width: 36,
                        child: Text(
                          '$pct%',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: pct > 0
                                    ? color
                                    : colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                  ],
                ),
              );
            }),

            // Pending proofs to vote on (exclude own)
            if (item.requiresProof &&
                pendingProofs
                    .where((p) => p.userId != currentUid)
                    .isNotEmpty) ...[
              const Divider(height: 20),
              Text(
                'Pending Proofs',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...pendingProofs
                  .where((p) => p.userId != currentUid)
                  .map((proof) => _PendingProofTile(
                        proof: proof,
                        color: color,
                        onVote: (approve) => onVoteProof(proof.id, approve),
                      )),
            ],
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

// ─── Proof Action Button ─────────────────────────────────────────────────────

class _ProofActionButton extends StatelessWidget {
  final GroupItem item;
  final ProofSubmission? myProof;
  final int myPercent;
  final Color color;
  final ColorScheme colorScheme;
  final Future<void> Function({
    required String proofType,
    String? caption,
    double? numericValue,
    String? numericUnit,
  }) onSubmitProof;

  const _ProofActionButton({
    required this.item,
    required this.myProof,
    required this.myPercent,
    required this.color,
    required this.colorScheme,
    required this.onSubmitProof,
  });

  @override
  Widget build(BuildContext context) {
    if (myProof != null) {
      // Already submitted proof
      final statusColor = myProof!.status == 'approved'
          ? Colors.green
          : myProof!.status == 'rejected'
              ? Colors.red
              : Colors.amber;
      final statusIcon = myProof!.status == 'approved'
          ? Icons.check_circle
          : myProof!.status == 'rejected'
              ? Icons.cancel
              : Icons.hourglass_top;
      final statusLabel = myProof!.status == 'approved'
          ? 'Approved'
          : myProof!.status == 'rejected'
              ? 'Rejected'
              : 'Pending';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, size: 14, color: statusColor),
            const SizedBox(width: 4),
            Text(
              statusLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ],
        ),
      );
    }

    // No proof yet: show submit button
    return GestureDetector(
      onTap: () => _showProofSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_proofTypeIcon(item.proofType), size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              'Submit Proof',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _proofTypeIcon(String type) {
    switch (type) {
      case 'photo':
        return Icons.camera_alt_outlined;
      case 'screenshot':
        return Icons.screenshot_outlined;
      case 'text':
        return Icons.edit_note;
      case 'numeric':
        return Icons.pin_outlined;
      default:
        return Icons.camera_alt_outlined;
    }
  }

  void _showProofSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SubmitProofSheet(
        item: item,
        onSubmit: onSubmitProof,
      ),
    );
  }
}

// ─── Submit Proof Sheet ──────────────────────────────────────────────────────

class _SubmitProofSheet extends StatefulWidget {
  final GroupItem item;
  final Future<void> Function({
    required String proofType,
    String? caption,
    double? numericValue,
    String? numericUnit,
  }) onSubmit;

  const _SubmitProofSheet({required this.item, required this.onSubmit});

  @override
  State<_SubmitProofSheet> createState() => _SubmitProofSheetState();
}

class _SubmitProofSheetState extends State<_SubmitProofSheet> {
  final _captionController = TextEditingController();
  final _numericController = TextEditingController();
  final _unitController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _captionController.dispose();
    _numericController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = Color(widget.item.color);
    final proofType = widget.item.proofType;

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
            Text(
              'Submit Proof',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.item.title,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: color),
            ),
            if (widget.item.proofDescription != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.item.proofDescription!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 16),

            if (proofType == 'numeric') ...[
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _numericController,
                      decoration: InputDecoration(
                        labelText: 'Value',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _unitController,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        hintText: 'e.g. km',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Caption / text proof field
            TextField(
              controller: _captionController,
              decoration: InputDecoration(
                labelText: proofType == 'text'
                    ? 'Describe what you did'
                    : 'Caption (optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: proofType == 'text' ? 3 : 1,
            ),

            if (proofType == 'photo' || proofType == 'screenshot') ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    Icon(
                      proofType == 'photo'
                          ? Icons.camera_alt_outlined
                          : Icons.screenshot_outlined,
                      size: 32,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      proofType == 'photo'
                          ? 'Photo upload coming soon'
                          : 'Screenshot upload coming soon',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: color),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Proof'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final caption = _captionController.text.trim();
    final proofType = widget.item.proofType;

    if (proofType == 'text' && caption.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe what you did.')),
      );
      return;
    }

    if (proofType == 'numeric' && _numericController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a value.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    await widget.onSubmit(
      proofType: proofType,
      caption: caption.isNotEmpty ? caption : null,
      numericValue: proofType == 'numeric'
          ? double.tryParse(_numericController.text.trim())
          : null,
      numericUnit: proofType == 'numeric'
          ? (_unitController.text.trim().isNotEmpty
              ? _unitController.text.trim()
              : null)
          : null,
    );

    if (mounted) Navigator.pop(context);
  }
}

// ─── Proof Status Badge ──────────────────────────────────────────────────────

class _ProofStatusBadge extends StatelessWidget {
  final String status;

  const _ProofStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color badgeColor;
    final IconData badgeIcon;

    switch (status) {
      case 'approved':
        badgeColor = Colors.green;
        badgeIcon = Icons.check_circle;
        break;
      case 'rejected':
        badgeColor = Colors.red;
        badgeIcon = Icons.cancel;
        break;
      default: // pending
        badgeColor = Colors.amber;
        badgeIcon = Icons.hourglass_top;
        break;
    }

    return SizedBox(
      width: 36,
      child: Icon(badgeIcon, size: 18, color: badgeColor),
    );
  }
}

// ─── Pending Proof Tile ──────────────────────────────────────────────────────

class _PendingProofTile extends StatelessWidget {
  final ProofSubmission proof;
  final Color color;
  final void Function(bool approve) onVote;

  const _PendingProofTile({
    required this.proof,
    required this.color,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = proof.submitterName ?? 'Member';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: color.withValues(alpha: 0.15),
                  backgroundImage: proof.submitterAvatar != null
                      ? NetworkImage(proof.submitterAvatar!)
                      : null,
                  child: proof.submitterAvatar == null
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: color),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${proof.votesApprove}/${proof.quorumSize} votes',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            if (proof.caption != null && proof.caption!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                proof.caption!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (proof.numericValue != null) ...[
              const SizedBox(height: 8),
              Text(
                '${proof.numericValue}${proof.numericUnit != null ? ' ${proof.numericUnit}' : ''}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => onVote(false),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => onVote(true),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
  final _descriptionController = TextEditingController();
  final _proofDescriptionController = TextEditingController();
  String _type = 'habit';
  String _selectedIcon = 'star';
  int _selectedColor = 0xFF4CAF50;
  bool _requiresProof = true;
  String _proofType = 'photo';
  bool _isSaving = false;

  final _icons = [
    'fitness_center',
    'water_drop',
    'book',
    'bed',
    'directions_run',
    'self_improvement',
    'restaurant',
    'savings',
    'cleaning_services',
    'school',
    'star',
    'favorite',
  ];

  final _colors = [
    0xFF4CAF50,
    0xFF2196F3,
    0xFFFF9800,
    0xFFE91E63,
    0xFF9C27B0,
    0xFF00BCD4,
    0xFFFF5722,
    0xFF607D8B,
  ];

  final _proofTypes = [
    {'value': 'photo', 'label': 'Photo', 'icon': Icons.camera_alt_outlined},
    {
      'value': 'screenshot',
      'label': 'Screenshot',
      'icon': Icons.screenshot_outlined
    },
    {'value': 'text', 'label': 'Text', 'icon': Icons.edit_note},
    {'value': 'numeric', 'label': 'Numeric', 'icon': Icons.pin_outlined},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _proofDescriptionController.dispose();
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
        child: SingleChildScrollView(
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
                  ButtonSegment(
                      value: 'habit',
                      label: Text('Habit'),
                      icon: Icon(Icons.repeat)),
                  ButtonSegment(
                      value: 'goal',
                      label: Text('Goal'),
                      icon: Icon(Icons.flag_outlined)),
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
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),

              // Description
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
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
                          color: isSelected
                              ? Colors.white
                              : colorScheme.onSurfaceVariant,
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
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Requires Proof switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Requires Proof'),
                subtitle: const Text(
                    'Members must submit proof of completion'),
                value: _requiresProof,
                onChanged: (v) => setState(() => _requiresProof = v),
              ),

              // Proof type dropdown (only shown if requires proof)
              if (_requiresProof) ...[
                const SizedBox(height: 8),
                Text('Proof Type',
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _proofTypes.map((pt) {
                      final isSelected = _proofType == pt['value'];
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _proofType = pt['value'] as String),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(_selectedColor)
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                pt['icon'] as IconData,
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                pt['label'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.white
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _proofDescriptionController,
                  decoration: InputDecoration(
                    labelText: 'Proof instructions (optional)',
                    hintText: 'e.g. Take a photo of your workout',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
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
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Add to Group'),
                ),
              ),
            ],
          ),
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
    final description = _descriptionController.text.trim();
    final proofDescription = _proofDescriptionController.text.trim();
    await widget.notifier.addItem(
      type: _type,
      title: title,
      description: description.isNotEmpty ? description : null,
      icon: _selectedIcon,
      color: _selectedColor,
      requiresProof: _requiresProof,
      proofType: _proofType,
      proofDescription:
          proofDescription.isNotEmpty ? proofDescription : null,
    );
    if (mounted) Navigator.pop(context);
  }
}
