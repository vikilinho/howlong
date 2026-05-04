import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:howlong/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:howlong/core/notifications/notification_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App Features Recording Test', (WidgetTester tester) async {
    // Initialize dependencies
    tz.initializeTimeZones();
    await NotificationService.instance.initialize();

    // Bypass biometrics for testing
    SharedPreferences.setMockInitialValues({'biometric_enabled': false});

    // Start app
    await tester.pumpWidget(
      const ProviderScope(
        child: HowLongApp(),
      ),
    );

    // Use pump with duration instead of pumpAndSettle to avoid
    // getting stuck on looping flutter_animate animations.
    await tester.pump(const Duration(seconds: 3));

    // ─── TODAY TAB ───
    // Linger on the Today screen to show it off
    await tester.pump(const Duration(seconds: 3));

    // ─── EVENTS TAB ───
    final eventsTab = find.text('EVENTS');
    if (tester.any(eventsTab)) {
      await tester.tap(eventsTab.last);
      await tester.pump(const Duration(seconds: 3));
    }

    // ─── Open Add Action screen ───
    final addActionFab = find.byTooltip('Add action');
    if (tester.any(addActionFab)) {
      await tester.tap(addActionFab.first);
      await tester.pump(const Duration(seconds: 3));

      // Go back
      final backButton = find.byTooltip('Back');
      if (tester.any(backButton)) {
        await tester.tap(backButton.first);
        await tester.pump(const Duration(seconds: 2));
      }
    }

    // ─── HABITS TAB ───
    final habitsTab = find.text('HABITS');
    if (tester.any(habitsTab)) {
      await tester.tap(habitsTab.last);
      await tester.pump(const Duration(seconds: 3));
    }

    // ─── Open Add Habit screen ───
    final addHabitFab = find.byTooltip('Add habit');
    if (tester.any(addHabitFab)) {
      await tester.tap(addHabitFab.first);
      await tester.pump(const Duration(seconds: 3));

      // Go back
      final backButton = find.byTooltip('Back');
      if (tester.any(backButton)) {
        await tester.tap(backButton.first);
        await tester.pump(const Duration(seconds: 2));
      }
    }

    // ─── LOGS TAB ───
    final logsTab = find.text('LOGS');
    if (tester.any(logsTab)) {
      await tester.tap(logsTab.last);
      await tester.pump(const Duration(seconds: 3));
    }

    // ─── Open Add Daily Log screen ───
    final addLogFab = find.byTooltip('Add daily log');
    if (tester.any(addLogFab)) {
      await tester.tap(addLogFab.first);
      await tester.pump(const Duration(seconds: 3));

      // Go back
      final backButton = find.byTooltip('Back');
      if (tester.any(backButton)) {
        await tester.tap(backButton.first);
        await tester.pump(const Duration(seconds: 2));
      }
    }

    // ─── BACK TO TODAY ───
    final todayTab = find.text('TODAY');
    if (tester.any(todayTab)) {
      await tester.tap(todayTab.last);
      await tester.pump(const Duration(seconds: 3));
    }

    // Final pause
    await tester.pump(const Duration(seconds: 2));
  });
}
