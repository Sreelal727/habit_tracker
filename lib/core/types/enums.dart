enum GoalType {
  daily,
  weekly,
  yearly;

  String get label {
    switch (this) {
      case GoalType.daily:
        return 'Daily';
      case GoalType.weekly:
        return 'Weekly';
      case GoalType.yearly:
        return 'Yearly';
    }
  }
}

enum HabitFrequency {
  daily,
  weekdays,
  custom;

  String get label {
    switch (this) {
      case HabitFrequency.daily:
        return 'Every day';
      case HabitFrequency.weekdays:
        return 'Weekdays';
      case HabitFrequency.custom:
        return 'Custom';
    }
  }
}
