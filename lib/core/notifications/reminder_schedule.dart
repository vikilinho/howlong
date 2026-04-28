class ReminderSchedule {
  ReminderSchedule._();

  static const Duration actionSnoozeInterval = Duration(minutes: 10);

  static Duration? actionReminderDuration({
    required int? value,
    required String unit,
  }) {
    if (value == null || value <= 0) return null;

    return switch (unit) {
      'minutes' => Duration(minutes: value),
      'hours' => Duration(hours: value),
      'weeks' => Duration(days: value * 7),
      'months' => Duration(days: value * 30),
      _ => Duration(days: value),
    };
  }

  static DateTime nextActionReminderTime({
    required DateTime dueAt,
    required DateTime now,
  }) {
    if (dueAt.isAfter(now)) {
      return dueAt;
    }

    var nextReminder = dueAt;
    while (!nextReminder.isAfter(now)) {
      nextReminder = nextReminder.add(actionSnoozeInterval);
    }
    return nextReminder;
  }
}
