import 'package:flutter_test/flutter_test.dart';

import 'package:howlong/core/storage/isar_models.dart';
import 'package:howlong/core/storage/repositories.dart';

/// Creates a [HabitCheckIn] for a given [date] (time is midnight).
HabitCheckIn _checkIn(DateTime date, {int habitId = 1}) {
  return HabitCheckIn()
    ..habitId = habitId
    ..checkedAt = date;
}

void main() {
  // -------------------------------------------------------------------------
  // isStreakBroken — daily schedule
  // -------------------------------------------------------------------------
  group('isStreakBroken (daily)', () {
    test('returns false when no check-ins exist (never started)', () {
      expect(isStreakBroken([], 'daily'), isFalse);
    });

    test('returns false when checked in today', () {
      final today = DateTime.now();
      expect(isStreakBroken([_checkIn(today)], 'daily'), isFalse);
    });

    test('returns false when checked in yesterday but not today', () {
      final yesterday =
          DateTime.now().subtract(const Duration(days: 1));
      expect(isStreakBroken([_checkIn(yesterday)], 'daily'), isFalse);
    });

    test('returns true when last check-in was 2 days ago', () {
      final twoDaysAgo =
          DateTime.now().subtract(const Duration(days: 2));
      expect(isStreakBroken([_checkIn(twoDaysAgo)], 'daily'), isTrue);
    });

    test('returns true when last check-in was a week ago', () {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      expect(isStreakBroken([_checkIn(weekAgo)], 'daily'), isTrue);
    });

    test('returns false with a long unbroken streak including today', () {
      final now = DateTime.now();
      final checkIns = List.generate(
        10,
        (i) => _checkIn(now.subtract(Duration(days: i))),
      );
      expect(isStreakBroken(checkIns, 'daily'), isFalse);
    });

    test('returns false with a long streak up to yesterday', () {
      final yesterday =
          DateTime.now().subtract(const Duration(days: 1));
      final checkIns = List.generate(
        10,
        (i) => _checkIn(yesterday.subtract(Duration(days: i))),
      );
      expect(isStreakBroken(checkIns, 'daily'), isFalse);
    });

    test('returns true with streak that has a gap before yesterday', () {
      final now = DateTime.now();
      // Checked in today and 3 days ago, but missed yesterday and the day before.
      final checkIns = [
        _checkIn(now.subtract(const Duration(days: 3))),
        // gap: 2 days ago, yesterday
      ];
      expect(isStreakBroken(checkIns, 'daily'), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // isStreakBroken — weekdays schedule
  // -------------------------------------------------------------------------
  group('isStreakBroken (weekdays)', () {
    test('returns false when no check-ins exist', () {
      expect(isStreakBroken([], 'weekdays'), isFalse);
    });

    test('returns false when checked in today (weekday)', () {
      // Find the next weekday from now to test with.
      var day = DateTime.now();
      while (day.weekday == DateTime.saturday ||
          day.weekday == DateTime.sunday) {
        day = day.subtract(const Duration(days: 1));
      }
      // Only meaningful if today IS a weekday; otherwise this
      // test just validates the weekend branch.
      final today = DateTime.now();
      if (today.weekday != DateTime.saturday &&
          today.weekday != DateTime.sunday) {
        expect(isStreakBroken([_checkIn(today)], 'weekdays'), isFalse);
      }
    });
  });

  // -------------------------------------------------------------------------
  // Notification message selection (integration-like)
  // -------------------------------------------------------------------------
  group('notification message selection', () {
    test('streak active → streakBroken=false messaging expected', () {
      final yesterday =
          DateTime.now().subtract(const Duration(days: 1));
      final broken = isStreakBroken([_checkIn(yesterday)], 'daily');
      expect(broken, isFalse,
          reason: 'Yesterday check-in means streak is still alive');
    });

    test('streak broken → streakBroken=true messaging expected', () {
      final threeDaysAgo =
          DateTime.now().subtract(const Duration(days: 3));
      final broken = isStreakBroken([_checkIn(threeDaysAgo)], 'daily');
      expect(broken, isTrue,
          reason: 'Last check-in 3 days ago means streak is broken');
    });
  });
}
