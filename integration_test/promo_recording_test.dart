import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:howlong/app.dart';
import 'package:howlong/core/storage/isar_models.dart';
import 'package:howlong/core/storage/isar_service.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Promo recording walkthrough', (WidgetTester tester) async {
    tz.initializeTimeZones();
    SharedPreferences.setMockInitialValues({'biometric_enabled': false});

    await _seedDemoData();

    await tester.pumpWidget(
      const ProviderScope(
        child: HowLongApp(),
      ),
    );

    await _hold(tester, 4);

    // Today screen
    await _hold(tester, 4);

    // Open an action detail from Today.
    await tester.tap(find.text('Drank Water').first);
    await _hold(tester, 3);
    await tester.tap(find.byTooltip('Back').first);
    await _hold(tester, 2);

    // Events tab and detail.
    await tester.tap(find.text('EVENTS').last);
    await _hold(tester, 3);
    await tester.tap(find.text('Fuelled Car').first);
    await _hold(tester, 3);
    await tester.tap(find.byTooltip('Back').first);
    await _hold(tester, 2);

    // Habits tab and detail.
    await tester.tap(find.text('HABITS').last);
    await _hold(tester, 3);
    await tester.tap(find.text('Morning Run').first);
    await _hold(tester, 4);
    await tester.tap(find.byTooltip('Back').first);
    await _hold(tester, 2);

    // Logs tab.
    await tester.tap(find.text('LOGS').last);
    await _hold(tester, 4);

    // Return to Today for a clean ending.
    await tester.tap(find.text('TODAY').last);
    await _hold(tester, 4);
  });
}

Future<void> _hold(WidgetTester tester, int seconds) {
  return tester.pump(Duration(seconds: seconds));
}

Future<void> _seedDemoData() async {
  final isar = await IsarService.instance;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  await isar.writeTxn(() async {
    await isar.clear();

    final drankWater = TrackedEvent()
      ..title = 'Drank Water'
      ..category = 'Health'
      ..lastPerformedAt = now.subtract(const Duration(hours: 1, minutes: 12))
      ..reminderAfterValue = 1
      ..reminderAfterUnit = 'hours'
      ..note = 'Stay hydrated through the day.'
      ..createdAt = now
      ..updatedAt = now;

    final fuelledCar = TrackedEvent()
      ..title = 'Fuelled Car'
      ..category = 'Car'
      ..lastPerformedAt = now.subtract(const Duration(days: 3, hours: 2))
      ..reminderAfterValue = 14
      ..reminderAfterUnit = 'days'
      ..note = 'Regular fuel top-up before commute.'
      ..createdAt = now
      ..updatedAt = now;

    final changedOil = TrackedEvent()
      ..title = 'Changed Oil'
      ..category = 'Car'
      ..lastPerformedAt = now.subtract(const Duration(days: 48))
      ..reminderAfterValue = 90
      ..reminderAfterUnit = 'days'
      ..note = 'Quarterly maintenance reminder.'
      ..createdAt = now
      ..updatedAt = now;

    await isar.trackedEvents.putAll([drankWater, fuelledCar, changedOil]);

    final morningRun = TrackedHabit()
      ..title = 'Morning Run'
      ..kind = 'build'
      ..schedule = 'daily'
      ..targetDays = 30
      ..reminderEnabled = true
      ..reminderMinutesAfterMidnight = 7 * 60
      ..createdAt = now
      ..updatedAt = now;

    final journaling = TrackedHabit()
      ..title = 'Journaling'
      ..kind = 'build'
      ..schedule = 'daily'
      ..targetDays = 21
      ..reminderEnabled = true
      ..reminderMinutesAfterMidnight = 21 * 60
      ..createdAt = now
      ..updatedAt = now;

    await isar.trackedHabits.putAll([morningRun, journaling]);

    final runCheckIns = List.generate(
      12,
      (index) => HabitCheckIn()
        ..habitId = morningRun.id
        ..checkedAt = today.subtract(Duration(days: index)),
    );
    final journalCheckIns = [
      HabitCheckIn()
        ..habitId = journaling.id
        ..checkedAt = today.subtract(const Duration(days: 1)),
      HabitCheckIn()
        ..habitId = journaling.id
        ..checkedAt = today.subtract(const Duration(days: 3)),
    ];
    await isar.habitCheckIns.putAll([...runCheckIns, ...journalCheckIns]);

    final dailyLogs = [
      DailyLog()
        ..day = today
        ..body =
            'Felt focused after the run. Water reminders helped me reset during work.'
        ..mood = 'Good'
        ..energy = 'High'
        ..createdAt = now
        ..updatedAt = now,
      DailyLog()
        ..day = today.subtract(const Duration(days: 1))
        ..body = 'A busier day, but journaling helped me slow down at night.'
        ..mood = 'Okay'
        ..energy = 'Medium'
        ..createdAt = now
        ..updatedAt = now,
    ];
    await isar.dailyLogs.putAll(dailyLogs);
  });
}
