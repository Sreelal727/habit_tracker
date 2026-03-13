import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'proof_notifier.dart';

class ProofSubmissionSheet extends ConsumerStatefulWidget {
  final String groupId;
  final String itemId;
  final String itemTitle;
  final String proofType; // photo, screenshot, text, numeric
  final String? proofDescription;
  final Color accentColor;

  const ProofSubmissionSheet({
    super.key,
    required this.groupId,
    required this.itemId,
    required this.itemTitle,
    required this.proofType,
    this.proofDescription,
    required this.accentColor,
  });

  @override
  ConsumerState<ProofSubmissionSheet> createState() =>
      _ProofSubmissionSheetState();
}

class _ProofSubmissionSheetState extends ConsumerState<ProofSubmissionSheet> {
  File? _imageFile;
  final _captionController = TextEditingController();
  final _numericController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final notifier = ref.read(proofProvider.notifier);
    final result = await notifier.submitProof(
      groupId: widget.groupId,
      itemId: widget.itemId,
      proofType: widget.proofType,
      imageFile: _imageFile,
      caption: _captionController.text.isNotEmpty
          ? _captionController.text
          : null,
      numericValue: _numericController.text.isNotEmpty
          ? double.tryParse(_numericController.text)
          : null,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result != null) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPhotoType =
        widget.proofType == 'photo' || widget.proofType == 'screenshot';
    final canSubmit = isPhotoType
        ? _imageFile != null
        : widget.proofType == 'numeric'
            ? _numericController.text.isNotEmpty
            : _captionController.text.isNotEmpty;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.verified, color: widget.accentColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submit Proof',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.itemTitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (widget.proofDescription != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: widget.accentColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.proofDescription!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Photo proof
            if (isPhotoType) ...[
              if (_imageFile != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _imageFile!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => setState(() => _imageFile = null),
                  icon: const Icon(Icons.close),
                  label: const Text('Remove'),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],

            // Text proof
            if (widget.proofType == 'text') ...[
              TextField(
                controller: _captionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Write your proof...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],

            // Numeric proof
            if (widget.proofType == 'numeric') ...[
              TextField(
                controller: _numericController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter value',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],

            // Optional caption for photo proofs
            if (isPhotoType && _imageFile != null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _captionController,
                decoration: InputDecoration(
                  hintText: 'Add a caption (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canSubmit && !_isSubmitting ? _submit : null,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSubmitting ? 'Uploading...' : 'Submit Proof'),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    _numericController.dispose();
    super.dispose();
  }
}
