import 'package:isar_community/isar.dart';

import 'isar_models.dart';

class EventsRepository {
  final Isar _isar;

  EventsRepository(this._isar);

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
  }

  Future<void> logNow(TrackedEvent event) async {
    final now = DateTime.now();
    await _isar.writeTxn(() async {
      event
        ..lastPerformedAt = now
        ..updatedAt = now;
      await _isar.trackedEvents.put(event);
    });
  }
}

class HabitsRepository {
  final Isar _isar;

  HabitsRepository(this._isar);

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
  }

  Future<void> checkInToday(TrackedHabit habit) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final existing = await _isar.habitCheckIns
        .filter()
        .habitIdEqualTo(habit.id)
        .checkedAtBetween(start, end)
        .findFirst();

    await _isar.writeTxn(() async {
      if (existing == null) {
        await _isar.habitCheckIns.put(
          HabitCheckIn()
            ..habitId = habit.id
            ..checkedAt = now,
        );
      }
      habit.updatedAt = now;
      await _isar.trackedHabits.put(habit);
    });
  }
}
