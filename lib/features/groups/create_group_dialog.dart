import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'groups_notifier.dart';

class CreateGroupDialog extends ConsumerStatefulWidget {
  final void Function(String groupId) onCreated;

  const CreateGroupDialog({super.key, required this.onCreated});

  @override
  ConsumerState<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends ConsumerState<CreateGroupDialog> {
  final _controller = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Group'),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: 'Group name',
          hintText: 'e.g. Morning Warriors',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) => _create(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _create,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _create() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    final notifier = ref.read(groupsProvider.notifier);
    final groupId = await notifier.createGroup(name);

    if (!mounted) return;
    Navigator.pop(context);
    if (groupId != null) {
      widget.onCreated(groupId);
    }
  }
}
