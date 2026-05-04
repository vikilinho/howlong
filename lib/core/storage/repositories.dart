import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';

import '../notifications/notification_service.dart';
import 'isar_models.dart';

class EventsRepository {
  final Isar _isar;
  final NotificationService _notifications;

  EventsRepository(
    this._isar, {
    NotificationService? notifications,
  }) : _notifications = notifications ?? NotificationService.instance;

  Stream<List<TrackedEvent>> watchEvents() {
    return _isar.trackedEvents.where().watch(fireImmediately: true).map(
      (events) {
        events.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return events;
      },
    );
  }

  Future<void> addEvent({
    required String title,
    required String category,
    required DateTime lastPerformedAt,
    int? reminderAfterValue,
    required String reminderAfterUnit,
    String? note,
  }) async {
    final now = DateTime.now();
    final event = TrackedEvent()
      ..title = title.trim()
      ..category = category
      ..lastPerformedAt = lastPerformedAt
      ..reminderAfterValue = reminderAfterValue
      ..reminderAfterUnit = reminderAfterUnit
      ..note = note?.trim().isEmpty ?? true ? null : note!.trim()
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.trackedEvents.put(event);
    });

    _runNotificationTask(() => _notifications.scheduleActionReminder(event));
  }

  Future<void> logNow(TrackedEvent event) async {
    final now = DateTime.now();
    await _isar.writeTxn(() async {
      event
        ..lastPerformedAt = now
        ..updatedAt = now;
      await _isar.trackedEvents.put(event);
    });

    _runNotificationTask(() => _notifications.scheduleActionReminder(event));
  }

  Future<void> renameEvent(TrackedEvent event, String title) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) return;

    await _isar.writeTxn(() async {
      event
        ..title = trimmedTitle
        ..updatedAt = DateTime.now();
      await _isar.trackedEvents.put(event);
    });

    _runNotificationTask(() => _notifications.scheduleActionReminder(event));
  }

  Future<void> updateEvent(
    TrackedEvent event, {
    required String title,
    required String category,
    required DateTime lastPerformedAt,
    int? reminderAfterValue,
    required String reminderAfterUnit,
    String? note,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) return;

    await _isar.writeTxn(() async {
      event
        ..title = trimmedTitle
        ..category = category
        ..lastPerformedAt = lastPerformedAt
        ..reminderAfterValue = reminderAfterValue
        ..reminderAfterUnit = reminderAfterUnit
        ..note = note?.trim().isEmpty ?? true ? null : note!.trim()
        ..updatedAt = DateTime.now();
      await _isar.trackedEvents.put(event);
    });

    _runNotificationTask(() => _notifications.scheduleActionReminder(event));
  }

  Future<void> deleteEvent(int id) async {
    await _isar.writeTxn(() async {
      await _isar.trackedEvents.delete(id);
    });
    _runNotificationTask(() => _notifications.cancelActionReminder(id));
  }
}

class HabitsRepository {
  final Isar _isar;
  final NotificationService _notifications;

  HabitsRepository(
    this._isar, {
    NotificationService? notifications,
  }) : _notifications = notifications ?? NotificationService.instance;

  Stream<List<TrackedHabit>> watchHabits() {
    return _isar.trackedHabits.where().watch(fireImmediately: true).map(
      (habits) {
        habits.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return habits;
      },
    );
  }

  Stream<List<HabitCheckIn>> watchCheckIns() {
    return _isar.habitCheckIns.where().watch(fireImmediately: true);
  }

  Future<void> addHabit({
    required String title,
    required String kind,
    required String schedule,
    required int targetDays,
    required bool reminderEnabled,
    int? reminderMinutesAfterMidnight,
  }) async {
    final now = DateTime.now();
    final habit = TrackedHabit()
      ..title = title.trim()
      ..kind = kind
      ..schedule = schedule
      ..targetDays = targetDays
      ..reminderEnabled = reminderEnabled
      ..reminderMinutesAfterMidnight = reminderMinutesAfterMidnight
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.trackedHabits.put(habit);
    });

    _runNotificationTask(() => _notifications.scheduleHabitReminder(habit));
  }

  Future<void> checkInToday(TrackedHabit habit) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final habitCheckIns =
        await _isar.habitCheckIns.filter().habitIdEqualTo(habit.id).findAll();
    final streakWasBroken = isStreakBroken(habitCheckIns, habit.schedule);
    final existing = await _isar.habitCheckIns
        .filter()
        .habitIdEqualTo(habit.id)
        .checkedAtBetween(start, end)
        .findFirst();

    await _isar.writeTxn(() async {
      if (existing == null) {
        if (streakWasBroken) {
          await _isar.habitCheckIns
              .filter()
              .habitIdEqualTo(habit.id)
              .deleteAll();
        }
        await _isar.habitCheckIns.put(
          HabitCheckIn()
            ..habitId = habit.id
            ..checkedAt = now,
        );
      }
      habit.updatedAt = now;
      await _isar.trackedHabits.put(habit);
    });

    _runNotificationTask(() => _notifications.scheduleHabitReminder(habit));
  }

  Future<void> renameHabit(TrackedHabit habit, String title) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) return;

    await _isar.writeTxn(() async {
      habit
        ..title = trimmedTitle
        ..updatedAt = DateTime.now();
      await _isar.trackedHabits.put(habit);
    });

    _runNotificationTask(() => _notifications.scheduleHabitReminder(habit));
  }

  Future<void> updateHabit(
    TrackedHabit habit, {
    required String title,
    required String kind,
    required String schedule,
    required int targetDays,
    required bool reminderEnabled,
    int? reminderMinutesAfterMidnight,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) return;

    await _isar.writeTxn(() async {
      habit
        ..title = trimmedTitle
        ..kind = kind
        ..schedule = schedule
        ..targetDays = targetDays
        ..reminderEnabled = reminderEnabled
        ..reminderMinutesAfterMidnight =
            reminderEnabled ? reminderMinutesAfterMidnight : null
        ..updatedAt = DateTime.now();
      await _isar.trackedHabits.put(habit);
    });

    _runNotificationTask(() => _notifications.scheduleHabitReminder(habit));
  }

  Future<void> deleteHabit(int id) async {
    await _isar.writeTxn(() async {
      await _isar.habitCheckIns.filter().habitIdEqualTo(id).deleteAll();
      await _isar.trackedHabits.delete(id);
    });
    _runNotificationTask(() => _notifications.cancelHabitReminder(id));
  }
}

void _runNotificationTask(Future<void> Function() task) {
  unawaited(() async {
    try {
      await task();
    } catch (error, stackTrace) {
      debugPrint('Notification task failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }());
}

class DailyLogsRepository {
  final Isar _isar;

  DailyLogsRepository(this._isar);

  Stream<List<DailyLog>> watchLogs() {
    return _isar.dailyLogs.where().watch(fireImmediately: true).map(
      (logs) {
        logs.sort((a, b) => b.day.compareTo(a.day));
        return logs;
      },
    );
  }

  Future<DailyLog?> findForDay(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return _isar.dailyLogs.filter().dayEqualTo(day).findFirst();
  }

  Future<void> saveLog({
    required DateTime day,
    required String body,
    required String mood,
    required String energy,
  }) async {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final existing = await findForDay(normalizedDay);
    final now = DateTime.now();
    final log = existing ?? DailyLog()
      ..day = normalizedDay
      ..createdAt = now;

    log
      ..body = body.trim()
      ..mood = mood
      ..energy = energy
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.dailyLogs.put(log);
    });
  }

  Future<void> deleteLog(int id) async {
    await _isar.writeTxn(() async {
      await _isar.dailyLogs.delete(id);
    });
  }
}

/// Determines whether a habit's streak is broken.
///
/// A streak is considered broken if the user did not check in on the most
/// recent expected day (today or yesterday, depending on schedule).
bool isStreakBroken(List<HabitCheckIn> checkIns, String schedule) {
  if (checkIns.isEmpty) return false; // Never started — not "broken".

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  final checkInDays = checkIns
      .map(
          (c) => DateTime(c.checkedAt.year, c.checkedAt.month, c.checkedAt.day))
      .toSet();

  // If checked in today, streak is not broken.
  if (checkInDays.contains(today)) return false;

  // For weekday-only habits, skip weekend gaps.
  if (schedule == 'weekdays') {
    // If today is a weekend, look at the last weekday.
    if (today.weekday == DateTime.saturday ||
        today.weekday == DateTime.sunday) {
      // Find the most recent Friday.
      var lastWeekday = today;
      while (lastWeekday.weekday != DateTime.friday) {
        lastWeekday = lastWeekday.subtract(const Duration(days: 1));
      }
      return !checkInDays.contains(lastWeekday);
    }

    // If today is Monday, yesterday was Sunday — check Friday instead.
    if (today.weekday == DateTime.monday) {
      final lastFriday = today.subtract(const Duration(days: 3));
      return !checkInDays.contains(lastFriday);
    }
  }

  // For daily (or weekday on a normal weekday): broken if yesterday is missing.
  return !checkInDays.contains(yesterday);
}
