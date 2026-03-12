import 'package:flutter/material.dart';

class DefaultHabits {
  DefaultHabits._();

  static const List<Map<String, dynamic>> habits = [
    {'name': 'Drink 4L Water', 'icon': 'water_drop', 'color': 0xFF2196F3},
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
