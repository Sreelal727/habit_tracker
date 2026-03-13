import 'package:flutter/material.dart';

/// Defines a customization field for a preset habit.
class HabitCustomField {
  final String key;
  final String label;
  final String type; // 'time', 'slider', 'choice'
  final dynamic defaultValue;
  final Map<String, dynamic>? options; // min/max for slider, choices for choice

  const HabitCustomField({
    required this.key,
    required this.label,
    required this.type,
    required this.defaultValue,
    this.options,
  });
}

/// A preset habit available during onboarding.
class PresetHabit {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int color;
  final String category;
  final List<HabitCustomField> customFields;

  const PresetHabit({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.category,
    this.customFields = const [],
  });

  /// Returns the default customization values as a map.
  Map<String, dynamic> get defaultCustomization {
    final map = <String, dynamic>{};
    for (final field in customFields) {
      map[field.key] = field.defaultValue;
    }
    return map;
  }
}

class PresetHabits {
  PresetHabits._();

  static const List<String> categories = [
    'Health',
    'Fitness',
    'Mindfulness',
    'Productivity',
    'Self-Care',
  ];

  static final List<PresetHabit> all = [
    // --- Health ---
    PresetHabit(
      id: 'drink_water',
      name: 'Drink Water',
      description: 'Stay hydrated throughout the day',
      icon: 'water_drop',
      color: 0xFF2196F3,
      category: 'Health',
      customFields: [
        HabitCustomField(
          key: 'target_liters',
          label: 'Daily target (liters)',
          type: 'slider',
          defaultValue: 3.0,
          options: {'min': 1.0, 'max': 6.0, 'step': 0.5, 'unit': 'L'},
        ),
      ],
    ),
    PresetHabit(
      id: 'eat_healthy',
      name: 'Eat Healthy',
      description: 'Track your healthy meals',
      icon: 'restaurant',
      color: 0xFF4CAF50,
      category: 'Health',
      customFields: [
        HabitCustomField(
          key: 'meals_per_day',
          label: 'Healthy meals per day',
          type: 'slider',
          defaultValue: 3.0,
          options: {'min': 1.0, 'max': 5.0, 'step': 1.0, 'unit': 'meals'},
        ),
        HabitCustomField(
          key: 'diet_type',
          label: 'Diet preference',
          type: 'choice',
          defaultValue: 'No preference',
          options: {
            'choices': [
              'No preference',
              'Vegetarian',
              'Vegan',
              'Keto',
              'Paleo',
              'Mediterranean',
            ],
          },
        ),
      ],
    ),
    PresetHabit(
      id: 'take_vitamins',
      name: 'Take Vitamins',
      description: 'Never miss your supplements',
      icon: 'medication',
      color: 0xFF00BCD4,
      category: 'Health',
      customFields: [
        HabitCustomField(
          key: 'time_of_day',
          label: 'When to take',
          type: 'choice',
          defaultValue: 'Morning',
          options: {
            'choices': ['Morning', 'Afternoon', 'Evening', 'Morning & Evening'],
          },
        ),
      ],
    ),
    PresetHabit(
      id: 'sleep_early',
      name: 'Sleep Early',
      description: 'Get to bed on time',
      icon: 'bed',
      color: 0xFF3F51B5,
      category: 'Health',
      customFields: [
        HabitCustomField(
          key: 'bedtime',
          label: 'Target bedtime',
          type: 'time',
          defaultValue: '22:00',
        ),
      ],
    ),

    // --- Fitness ---
    PresetHabit(
      id: 'wake_up_early',
      name: 'Wake Up Early',
      description: 'Start your day with purpose',
      icon: 'alarm',
      color: 0xFFFF9800,
      category: 'Fitness',
      customFields: [
        HabitCustomField(
          key: 'wake_time',
          label: 'Target wake-up time',
          type: 'time',
          defaultValue: '06:00',
        ),
      ],
    ),
    PresetHabit(
      id: 'hit_the_gym',
      name: 'Hit the Gym',
      description: 'Build your workout routine',
      icon: 'fitness_center',
      color: 0xFFE91E63,
      category: 'Fitness',
      customFields: [
        HabitCustomField(
          key: 'duration_minutes',
          label: 'Workout duration (minutes)',
          type: 'slider',
          defaultValue: 60.0,
          options: {'min': 15.0, 'max': 120.0, 'step': 15.0, 'unit': 'min'},
        ),
        HabitCustomField(
          key: 'workout_type',
          label: 'Workout type',
          type: 'choice',
          defaultValue: 'Mixed',
          options: {
            'choices': [
              'Mixed',
              'Strength',
              'Cardio',
              'HIIT',
              'Yoga',
              'CrossFit',
            ],
          },
        ),
      ],
    ),
    PresetHabit(
      id: 'walk_run',
      name: 'Walk / Run',
      description: 'Daily walking or running goal',
      icon: 'directions_run',
      color: 0xFF795548,
      category: 'Fitness',
      customFields: [
        HabitCustomField(
          key: 'target_steps',
          label: 'Daily steps target',
          type: 'slider',
          defaultValue: 8000.0,
          options: {
            'min': 3000.0,
            'max': 20000.0,
            'step': 1000.0,
            'unit': 'steps',
          },
        ),
      ],
    ),
    PresetHabit(
      id: 'stretch',
      name: 'Stretch',
      description: 'Improve flexibility and recovery',
      icon: 'self_improvement',
      color: 0xFFFF7043,
      category: 'Fitness',
      customFields: [
        HabitCustomField(
          key: 'duration_minutes',
          label: 'Duration (minutes)',
          type: 'slider',
          defaultValue: 15.0,
          options: {'min': 5.0, 'max': 45.0, 'step': 5.0, 'unit': 'min'},
        ),
      ],
    ),

    // --- Mindfulness ---
    PresetHabit(
      id: 'meditate',
      name: 'Meditate',
      description: 'Calm your mind daily',
      icon: 'self_improvement',
      color: 0xFF9C27B0,
      category: 'Mindfulness',
      customFields: [
        HabitCustomField(
          key: 'duration_minutes',
          label: 'Session duration (minutes)',
          type: 'slider',
          defaultValue: 10.0,
          options: {'min': 5.0, 'max': 60.0, 'step': 5.0, 'unit': 'min'},
        ),
        HabitCustomField(
          key: 'meditation_type',
          label: 'Meditation style',
          type: 'choice',
          defaultValue: 'Mindfulness',
          options: {
            'choices': [
              'Mindfulness',
              'Guided',
              'Breathing',
              'Body Scan',
              'Loving-Kindness',
            ],
          },
        ),
      ],
    ),
    PresetHabit(
      id: 'journal',
      name: 'Journal',
      description: 'Write down your thoughts',
      icon: 'book',
      color: 0xFF8D6E63,
      category: 'Mindfulness',
      customFields: [
        HabitCustomField(
          key: 'journal_time',
          label: 'Preferred time',
          type: 'choice',
          defaultValue: 'Evening',
          options: {
            'choices': ['Morning', 'Evening', 'Anytime'],
          },
        ),
      ],
    ),
    PresetHabit(
      id: 'gratitude',
      name: 'Practice Gratitude',
      description: 'Note things you are grateful for',
      icon: 'favorite',
      color: 0xFFE91E63,
      category: 'Mindfulness',
      customFields: [
        HabitCustomField(
          key: 'items_count',
          label: 'Things to list daily',
          type: 'slider',
          defaultValue: 3.0,
          options: {'min': 1.0, 'max': 10.0, 'step': 1.0, 'unit': 'items'},
        ),
      ],
    ),

    // --- Productivity ---
    PresetHabit(
      id: 'read_books',
      name: 'Read Books',
      description: 'Build a daily reading habit',
      icon: 'book',
      color: 0xFF607D8B,
      category: 'Productivity',
      customFields: [
        HabitCustomField(
          key: 'reading_minutes',
          label: 'Reading time (minutes)',
          type: 'slider',
          defaultValue: 30.0,
          options: {'min': 10.0, 'max': 120.0, 'step': 10.0, 'unit': 'min'},
        ),
      ],
    ),
    PresetHabit(
      id: 'learn_something',
      name: 'Learn Something New',
      description: 'Dedicate time to learning',
      icon: 'school',
      color: 0xFF3F51B5,
      category: 'Productivity',
      customFields: [
        HabitCustomField(
          key: 'duration_minutes',
          label: 'Study time (minutes)',
          type: 'slider',
          defaultValue: 30.0,
          options: {'min': 15.0, 'max': 120.0, 'step': 15.0, 'unit': 'min'},
        ),
        HabitCustomField(
          key: 'subject',
          label: 'Subject',
          type: 'choice',
          defaultValue: 'General',
          options: {
            'choices': [
              'General',
              'Language',
              'Programming',
              'Music',
              'Art',
              'Science',
            ],
          },
        ),
      ],
    ),
    PresetHabit(
      id: 'no_social_media',
      name: 'Limit Social Media',
      description: 'Reduce screen time',
      icon: 'smoke_free',
      color: 0xFFF44336,
      category: 'Productivity',
      customFields: [
        HabitCustomField(
          key: 'max_minutes',
          label: 'Max daily usage (minutes)',
          type: 'slider',
          defaultValue: 30.0,
          options: {'min': 0.0, 'max': 120.0, 'step': 15.0, 'unit': 'min'},
        ),
      ],
    ),
    PresetHabit(
      id: 'save_money',
      name: 'Save Money',
      description: 'Track daily savings',
      icon: 'savings',
      color: 0xFF4CAF50,
      category: 'Productivity',
      customFields: [
        HabitCustomField(
          key: 'daily_amount',
          label: 'Daily savings target',
          type: 'slider',
          defaultValue: 100.0,
          options: {'min': 10.0, 'max': 1000.0, 'step': 10.0, 'unit': '\$'},
        ),
      ],
    ),

    // --- Self-Care ---
    PresetHabit(
      id: 'skincare',
      name: 'Skincare Routine',
      description: 'Take care of your skin',
      icon: 'spa',
      color: 0xFFFF5722,
      category: 'Self-Care',
      customFields: [
        HabitCustomField(
          key: 'routine_time',
          label: 'Routine time',
          type: 'choice',
          defaultValue: 'Morning & Night',
          options: {
            'choices': ['Morning', 'Night', 'Morning & Night'],
          },
        ),
      ],
    ),
    PresetHabit(
      id: 'clean_house',
      name: 'Clean / Tidy Up',
      description: 'Keep your space organized',
      icon: 'cleaning_services',
      color: 0xFF26A69A,
      category: 'Self-Care',
      customFields: [
        HabitCustomField(
          key: 'duration_minutes',
          label: 'Cleaning time (minutes)',
          type: 'slider',
          defaultValue: 15.0,
          options: {'min': 5.0, 'max': 60.0, 'step': 5.0, 'unit': 'min'},
        ),
      ],
    ),
  ];

  static List<PresetHabit> byCategory(String category) {
    return all.where((h) => h.category == category).toList();
  }
}

// Keep for backward compatibility
class DefaultHabits {
  DefaultHabits._();

  static const List<Map<String, dynamic>> habits = [
    {'name': 'Drink Water', 'icon': 'water_drop', 'color': 0xFF2196F3},
    {'name': 'Wake Up Early', 'icon': 'alarm', 'color': 0xFFFF9800},
    {'name': 'Hit the Gym', 'icon': 'fitness_center', 'color': 0xFFE91E63},
    {'name': 'Eat Healthy', 'icon': 'restaurant', 'color': 0xFF4CAF50},
    {'name': 'Meditate', 'icon': 'self_improvement', 'color': 0xFF9C27B0},
    {'name': 'Take Vitamins', 'icon': 'medication', 'color': 0xFF00BCD4},
    {'name': 'Skincare', 'icon': 'spa', 'color': 0xFFFF5722},
  ];
}

class HabitIcons {
  HabitIcons._();

  static const Map<String, IconData> icons = {
    'water_drop': Icons.water_drop,
    'alarm': Icons.alarm,
    'fitness_center': Icons.fitness_center,
    'restaurant': Icons.restaurant,
    'self_improvement': Icons.self_improvement,
    'medication': Icons.medication,
    'spa': Icons.spa,
    'book': Icons.book,
    'code': Icons.code,
    'music_note': Icons.music_note,
    'directions_run': Icons.directions_run,
    'bed': Icons.bed,
    'smoke_free': Icons.smoke_free,
    'savings': Icons.savings,
    'brush': Icons.brush,
    'school': Icons.school,
    'pets': Icons.pets,
    'local_grocery_store': Icons.local_grocery_store,
    'cleaning_services': Icons.cleaning_services,
    'star': Icons.star,
    'favorite': Icons.favorite,
  };

  static IconData getIcon(String key) {
    return icons[key] ?? Icons.check_circle;
  }
}

class StreakThresholds {
  StreakThresholds._();

  static const int fireIcon = 7;
  static const int bronze = 21;
  static const int silver = 30;
  static const int gold = 60;
  static const int diamond = 100;
}

class CoinRewards {
  CoinRewards._();

  static const int dailyBase = 10;
  static const int streakBonusPerDay = 2;
  static const int maxStreakBonus = 20;
}

class PremiumFeatures {
  PremiumFeatures._();

  static const Map<String, Map<String, dynamic>> features = {
    'theme_ocean': {
      'name': 'Ocean Theme',
      'description': 'Cool blue ocean-inspired theme',
      'cost': 100,
      'icon': 'palette',
    },
    'theme_sunset': {
      'name': 'Sunset Theme',
      'description': 'Warm sunset gradient theme',
      'cost': 100,
      'icon': 'palette',
    },
    'theme_forest': {
      'name': 'Forest Theme',
      'description': 'Deep green forest theme',
      'cost': 100,
      'icon': 'palette',
    },
    'advanced_graphs': {
      'name': 'Advanced Analytics',
      'description': 'Detailed charts and insights',
      'cost': 250,
      'icon': 'analytics',
    },
    'calendar_view': {
      'name': 'Calendar View',
      'description': 'Color-coded habit calendar',
      'cost': 200,
      'icon': 'calendar_month',
    },
  };
}
