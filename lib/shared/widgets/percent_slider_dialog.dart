import 'package:flutter/material.dart';

class PercentSliderDialog extends StatefulWidget {
  final String title;
  final int initialPercent;
  final Color? accentColor;

  const PercentSliderDialog({
    super.key,
    required this.title,
    this.initialPercent = 0,
    this.accentColor,
  });

  @override
  State<PercentSliderDialog> createState() => _PercentSliderDialogState();
}

class _PercentSliderDialogState extends State<PercentSliderDialog> {
  late int _percent;

  @override
  void initState() {
    super.initState();
    _percent = widget.initialPercent;
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor ?? Theme.of(context).colorScheme.primary;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 20),
          // Circular progress
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: _percent / 100,
                    strokeWidth: 8,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: color,
                  ),
                ),
                Text(
                  '$_percent%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
              overlayColor: color.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: _percent.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              label: '$_percent%',
              onChanged: (v) => setState(() => _percent = v.round()),
            ),
          ),
          const SizedBox(height: 8),
          // Quick-tap buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [0, 25, 50, 75, 100].map((p) {
              final isActive = _percent == p;
              return GestureDetector(
                onTap: () => setState(() => _percent = p),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? color : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$p%',
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : colorScheme.onSurface,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_percent),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
