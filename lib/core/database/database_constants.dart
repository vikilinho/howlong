class DatabaseConstants {
  DatabaseConstants._();

  static const String dbName = 'howlong.db';
  static const int dbVersion = 1;

  static const String tableEvents = 'events';
  static const String tableEventLogs = 'event_logs';
  static const String tableHabits = 'habits';
  static const String tableHabitLogs = 'habit_logs';

  // Events columns
  static const String colEventsId = 'id';
  static const String colEventsTitle = 'title';
  static const String colEventsEmoji = 'emoji';
  static const String colEventsLastLoggedAt = 'last_logged_at';
  static const String colEventsReminderAfterDays = 'reminder_after_days';
  static const String colEventsCreatedAt = 'created_at';

  // Event Logs columns
  static const String colEventLogsId = 'id';
  static const String colEventLogsEventId = 'event_id';
  static const String colEventLogsLoggedAt = 'logged_at';
  static const String colEventLogsNote = 'note';

  // Habits columns
  static const String colHabitsId = 'id';
  static const String colHabitsTitle = 'title';
  static const String colHabitsEmoji = 'emoji';
  static const String colHabitsHabitType = 'habit_type';
  static const String colHabitsScheduleType = 'schedule_type';
  static const String colHabitsScheduleDays = 'schedule_days';
  static const String colHabitsScheduleEveryXDays = 'schedule_every_x_days';
  static const String colHabitsNotificationTime = 'notification_time';
  static const String colHabitsColorHex = 'color_hex';
  static const String colHabitsCreatedAt = 'created_at';

  // Habit Logs columns
  static const String colHabitLogsId = 'id';
  static const String colHabitLogsHabitId = 'habit_id';
  static const String colHabitLogsCheckedAt = 'checked_at';
  static const String colHabitLogsStatus = 'status';
}
