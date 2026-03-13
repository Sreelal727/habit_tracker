import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
import '../../config/constants.dart';
import '../../config/theme/app_colors.dart';
import '../../core/database/app_database.dart';
import '../../providers/app_providers.dart';

const _uuid = Uuid();

class HabitSelectionScreen extends ConsumerStatefulWidget {
  const HabitSelectionScreen({super.key});

  @override
  ConsumerState<HabitSelectionScreen> createState() =>
      _HabitSelectionScreenState();
}

class _HabitSelectionScreenState extends ConsumerState<HabitSelectionScreen> {
  final Map<String, Map<String, dynamic>> _selectedHabits = {};
  String _activeCategory = PresetHabits.categories.first;
  bool _isSaving = false;

  void _toggleHabit(PresetHabit preset) {
    setState(() {
      if (_selectedHabits.containsKey(preset.id)) {
        _selectedHabits.remove(preset.id);
      } else {
        _selectedHabits[preset.id] = Map.from(preset.defaultCustomization);
      }
    });
  }

  void _openCustomization(PresetHabit preset) {
    if (!_selectedHabits.containsKey(preset.id)) {
      _selectedHabits[preset.id] = Map.from(preset.defaultCustomization);
      setState(() {});
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CustomizationSheet(
        preset: preset,
        currentValues: Map.from(_selectedHabits[preset.id]!),
        onSave: (values) {
          setState(() {
            _selectedHabits[preset.id] = values;
          });
        },
      ),
    );
  }

  Future<void> _saveAndContinue() async {
    if (_selectedHabits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one habit')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final habitDao = ref.read(habitDaoProvider);
    final settingsDao = ref.read(userSettingsDaoProvider);

    int sortOrder = 0;
    for (final entry in _selectedHabits.entries) {
      final preset = PresetHabits.all.firstWhere((p) => p.id == entry.key);
      final customization = entry.value;

      // Build display name with customization
      String displayName = _buildDisplayName(preset, customization);

      await habitDao.insertHabit(HabitsCompanion.insert(
        id: _uuid.v4(),
        name: displayName,
        icon: Value(preset.icon),
        color: Value(preset.color),
        sortOrder: Value(sortOrder),
        customization: Value(jsonEncode(customization)),
      ));
      sortOrder++;
    }

    await settingsDao.setBool('habits_seeded', true);
    await settingsDao.setBool('onboarding_complete', true);

    if (mounted) {
      context.go('/today');
    }
  }

  String _buildDisplayName(
      PresetHabit preset, Map<String, dynamic> customization) {
    switch (preset.id) {
      case 'drink_water':
        final liters = customization['target_liters'] ?? 3.0;
        return 'Drink ${liters % 1 == 0 ? liters.toInt() : liters}L Water';
      case 'wake_up_early':
        final time = customization['wake_time'] ?? '06:00';
        return 'Wake Up by $time';
      case 'sleep_early':
        final time = customization['bedtime'] ?? '22:00';
        return 'Sleep by $time';
      case 'hit_the_gym':
        final mins = (customization['duration_minutes'] ?? 60.0).toInt();
        final type = customization['workout_type'] ?? 'Mixed';
        return '$type Workout (${mins}min)';
      case 'meditate':
        final mins = (customization['duration_minutes'] ?? 10.0).toInt();
        return 'Meditate ${mins}min';
      case 'walk_run':
        final steps = (customization['target_steps'] ?? 8000.0).toInt();
        return 'Walk ${steps >= 1000 ? '${(steps / 1000).toStringAsFixed(0)}K' : steps} Steps';
      case 'read_books':
        final mins = (customization['reading_minutes'] ?? 30.0).toInt();
        return 'Read ${mins}min';
      case 'no_social_media':
        final maxMins = (customization['max_minutes'] ?? 30.0).toInt();
        return 'Social Media < ${maxMins}min';
      case 'eat_healthy':
        final meals = (customization['meals_per_day'] ?? 3.0).toInt();
        return 'Eat $meals Healthy Meals';
      case 'learn_something':
        final mins = (customization['duration_minutes'] ?? 30.0).toInt();
        final subject = customization['subject'] ?? 'General';
        return subject == 'General'
            ? 'Learn ${mins}min'
            : 'Learn $subject (${mins}min)';
      case 'stretch':
        final mins = (customization['duration_minutes'] ?? 15.0).toInt();
        return 'Stretch ${mins}min';
      case 'clean_house':
        final mins = (customization['duration_minutes'] ?? 15.0).toInt();
        return 'Tidy Up (${mins}min)';
      case 'save_money':
        final amount = (customization['daily_amount'] ?? 100.0).toInt();
        return 'Save \$$amount Daily';
      case 'gratitude':
        final count = (customization['items_count'] ?? 3.0).toInt();
        return 'Gratitude ($count things)';
      default:
        return preset.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryHabits = PresetHabits.byCategory(_activeCategory);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Your Habits',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select habits you want to build. Tap the settings icon to customize each one.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Category tabs
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: PresetHabits.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = PresetHabits.categories[index];
                  final isActive = cat == _activeCategory;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isActive,
                    onSelected: (_) =>
                        setState(() => _activeCategory = cat),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[700],
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Habit list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categoryHabits.length,
                itemBuilder: (context, index) {
                  final preset = categoryHabits[index];
                  final isSelected =
                      _selectedHabits.containsKey(preset.id);
                  final customValues = _selectedHabits[preset.id];

                  return _HabitCard(
                    preset: preset,
                    isSelected: isSelected,
                    customValues: customValues,
                    onToggle: () => _toggleHabit(preset),
                    onCustomize: () => _openCustomization(preset),
                    buildDisplayName: _buildDisplayName,
                  );
                },
              ),
            ),

            // Bottom bar
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    '${_selectedHabits.length} selected',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveAndContinue,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.arrow_forward),
                    label: const Text('Continue'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final PresetHabit preset;
  final bool isSelected;
  final Map<String, dynamic>? customValues;
  final VoidCallback onToggle;
  final VoidCallback onCustomize;
  final String Function(PresetHabit, Map<String, dynamic>) buildDisplayName;

  const _HabitCard({
    required this.preset,
    required this.isSelected,
    required this.customValues,
    required this.onToggle,
    required this.onCustomize,
    required this.buildDisplayName,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(preset.color);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: color, width: 2)
            : BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  HabitIcons.getIcon(preset.icon),
                  color: isSelected ? Colors.white : color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSelected && customValues != null
                          ? buildDisplayName(preset, customValues!)
                          : preset.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preset.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    if (isSelected && customValues != null) ...[
                      const SizedBox(height: 4),
                      _buildCustomSummary(context, customValues!),
                    ],
                  ],
                ),
              ),

              // Customize button
              if (isSelected && preset.customFields.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.tune, color: color),
                  onPressed: onCustomize,
                  tooltip: 'Customize',
                ),

              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomSummary(
      BuildContext context, Map<String, dynamic> values) {
    final chips = <Widget>[];
    for (final field in preset.customFields) {
      final value = values[field.key];
      if (value != null) {
        String display;
        if (field.type == 'slider') {
          final unit = field.options?['unit'] ?? '';
          final num = value is double && value % 1 == 0
              ? value.toInt()
              : value;
          display = '$num $unit';
        } else {
          display = value.toString();
        }
        chips.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Color(preset.color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              display,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Color(preset.color),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        );
      }
    }
    return Wrap(spacing: 6, children: chips);
  }
}

class _CustomizationSheet extends StatefulWidget {
  final PresetHabit preset;
  final Map<String, dynamic> currentValues;
  final ValueChanged<Map<String, dynamic>> onSave;

  const _CustomizationSheet({
    required this.preset,
    required this.currentValues,
    required this.onSave,
  });

  @override
  State<_CustomizationSheet> createState() => _CustomizationSheetState();
}

class _CustomizationSheetState extends State<_CustomizationSheet> {
  late Map<String, dynamic> _values;

  @override
  void initState() {
    super.initState();
    _values = Map.from(widget.currentValues);
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.preset.color);
    final theme = Theme.of(context);

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
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    HabitIcons.getIcon(widget.preset.icon),
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Customize ${widget.preset.name}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Fields
            ...widget.preset.customFields
                .map((field) => _buildField(field, color)),

            const SizedBox(height: 16),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  widget.onSave(_values);
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(HabitCustomField field, Color color) {
    switch (field.type) {
      case 'time':
        return _buildTimePicker(field, color);
      case 'slider':
        return _buildSlider(field, color);
      case 'choice':
        return _buildChoicePicker(field, color);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTimePicker(HabitCustomField field, Color color) {
    final timeStr = _values[field.key] as String? ?? field.defaultValue;
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: hour, minute: minute),
              );
              if (picked != null) {
                setState(() {
                  _values[field.key] =
                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                });
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: color, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    TimeOfDay(hour: hour, minute: minute).format(context),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Icon(Icons.edit, color: Colors.grey[400], size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(HabitCustomField field, Color color) {
    final value =
        (_values[field.key] as num?)?.toDouble() ?? field.defaultValue;
    final min = (field.options?['min'] as num?)?.toDouble() ?? 0.0;
    final max = (field.options?['max'] as num?)?.toDouble() ?? 100.0;
    final step = (field.options?['step'] as num?)?.toDouble() ?? 1.0;
    final unit = field.options?['unit'] ?? '';
    final divisions = ((max - min) / step).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(field.label,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value % 1 == 0 ? value.toInt() : value} $unit',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
              overlayColor: color.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: (v) {
                setState(() {
                  _values[field.key] = v;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoicePicker(HabitCustomField field, Color color) {
    final choices =
        (field.options?['choices'] as List?)?.cast<String>() ?? [];
    final selected = _values[field.key] ?? field.defaultValue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: choices.map((choice) {
              final isActive = choice == selected;
              return ChoiceChip(
                label: Text(choice),
                selected: isActive,
                onSelected: (_) {
                  setState(() {
                    _values[field.key] = choice;
                  });
                },
                selectedColor: color,
                labelStyle: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[700],
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
