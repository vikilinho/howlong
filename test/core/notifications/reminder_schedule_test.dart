import 'package:flutter_test/flutter_test.dart';
import 'package:howlong/core/notifications/reminder_schedule.dart';

void main() {
  group('ReminderSchedule.actionReminderDuration', () {
    test('returns null when reminder value is missing or not positive', () {
      expect(
        ReminderSchedule.actionReminderDuration(value: null, unit: 'minutes'),
        isNull,
      );
      expect(
        ReminderSchedule.actionReminderDuration(value: 0, unit: 'minutes'),
        isNull,
      );
      expect(
        ReminderSchedule.actionReminderDuration(value: -1, unit: 'minutes'),
        isNull,
      );
    });

    test('converts supported reminder units into durations', () {
      expect(
        ReminderSchedule.actionReminderDuration(value: 5, unit: 'minutes'),
        const Duration(minutes: 5),
      );
      expect(
        ReminderSchedule.actionReminderDuration(value: 2, unit: 'hours'),
        const Duration(hours: 2),
      );
      expect(
        ReminderSchedule.actionReminderDuration(value: 3, unit: 'days'),
        const Duration(days: 3),
      );
      expect(
        ReminderSchedule.actionReminderDuration(value: 2, unit: 'weeks'),
        const Duration(days: 14),
      );
      expect(
        ReminderSchedule.actionReminderDuration(value: 2, unit: 'months'),
        const Duration(days: 60),
      );
    });

    test('falls back to days for unknown units', () {
      expect(
        ReminderSchedule.actionReminderDuration(value: 4, unit: 'something'),
        const Duration(days: 4),
      );
    });
  });

  group('ReminderSchedule.nextActionReminderTime', () {
    final dueAt = DateTime(2026, 4, 28, 21, 35);

    test('uses the original due time when it is still in the future', () {
      final nextReminder = ReminderSchedule.nextActionReminderTime(
        dueAt: dueAt,
        now: DateTime(2026, 4, 28, 21, 34),
      );

      expect(nextReminder, dueAt);
    });

    test('snoozes 10 minutes after the first due time when overdue', () {
      final nextReminder = ReminderSchedule.nextActionReminderTime(
        dueAt: dueAt,
        now: DateTime(2026, 4, 28, 21, 42),
      );

      expect(nextReminder, DateTime(2026, 4, 28, 21, 45));
    });

    test('skips missed snooze slots and picks the next future slot', () {
      final nextReminder = ReminderSchedule.nextActionReminderTime(
        dueAt: dueAt,
        now: DateTime(2026, 4, 28, 21, 48),
      );

      expect(nextReminder, DateTime(2026, 4, 28, 21, 55));
    });

    test('does not schedule at the exact current time', () {
      final nextReminder = ReminderSchedule.nextActionReminderTime(
        dueAt: dueAt,
        now: DateTime(2026, 4, 28, 21, 45),
      );

      expect(nextReminder, DateTime(2026, 4, 28, 21, 55));
    });
  });
}
