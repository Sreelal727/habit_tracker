import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'groups_notifier.dart';

class JoinGroupDialog extends ConsumerStatefulWidget {
  final void Function(String groupId) onJoined;

  const JoinGroupDialog({super.key, required this.onJoined});

  @override
  ConsumerState<JoinGroupDialog> createState() => _JoinGroupDialogState();
}

class _JoinGroupDialogState extends ConsumerState<JoinGroupDialog> {
  final _controller = TextEditingController();
  bool _isJoining = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join Group'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter the 6-character invite code shared by the group creator.'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Invite Code',
              hintText: 'e.g. AB3X7K',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              errorText: _errorText,
              counterText: '',
            ),
            autofocus: true,
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
            onSubmitted: (_) => _join(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isJoining ? null : _join,
          child: _isJoining
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Join'),
        ),
      ],
    );
  }

  Future<void> _join() async {
    final code = _controller.text.trim();
    if (code.length < 6) {
      setState(() => _errorText = 'Please enter a 6-character code');
      return;
    }

    setState(() {
      _isJoining = true;
      _errorText = null;
    });

    final notifier = ref.read(groupsProvider.notifier);
    final groupId = await notifier.joinGroup(code);

    if (!mounted) return;

    if (groupId != null) {
      Navigator.pop(context);
      widget.onJoined(groupId);
    } else {
      final error = ref.read(groupsProvider).error ?? 'Group not found.';
      setState(() {
        _isJoining = false;
        _errorText = error;
      });
      notifier.clearError();
    }
  }
}
