import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

import '../storage/isar_models.dart';
import 'reminder_schedule.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const AndroidNotificationChannel _remindersChannel =
      AndroidNotificationChannel(
    'howlong_reminders',
    'HowLong reminders',
    description: 'Action and habit reminders from HowLong.',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    await _configureLocalTimezone();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_remindersChannel);

    await requestPermissions();
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return;
    }

    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return;
    }

    if (Platform.isMacOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> scheduleActionReminder(TrackedEvent event) async {
    await initialize();
    await cancelActionReminder(event.id);

    final reminderDuration = ReminderSchedule.actionReminderDuration(
      value: event.reminderAfterValue,
      unit: event.reminderAfterUnit,
    );
    if (reminderDuration == null) return;

    final dueAt = event.lastPerformedAt.add(reminderDuration);
    final effectiveSchedule = ReminderSchedule.nextActionReminderTime(
      dueAt: dueAt,
      now: DateTime.now(),
    );

    await _plugin.zonedSchedule(
      _actionNotificationId(event.id),
      'How long since ${event.title}?',
      'It is time to log this action again.',
      _toTzDateTime(effectiveSchedule),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'action:${event.id}',
    );
  }

  Future<void> scheduleHabitReminder(TrackedHabit habit) async {
    await initialize();
    await cancelHabitReminder(habit.id);

    if (!habit.reminderEnabled) return;
    final minutes = habit.reminderMinutesAfterMidnight;
    if (minutes == null) return;

    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final title = habit.kind == 'break'
        ? 'Keep away from ${habit.title}'
        : 'Check in: ${habit.title}';
    final body = habit.kind == 'break'
        ? 'A small pause now protects the streak you are building.'
        : 'Log today when this is done.';

    if (habit.schedule == 'weekdays') {
      for (var weekday = DateTime.monday;
          weekday <= DateTime.friday;
          weekday++) {
        await _scheduleWeeklyHabitReminder(
          habit: habit,
          weekday: weekday,
          hour: hour,
          minute: minute,
          title: title,
          body: body,
        );
      }
      return;
    }

    await _plugin.zonedSchedule(
      _habitNotificationId(habit.id),
      title,
      body,
      _nextDailyTime(hour, minute),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'habit:${habit.id}',
    );
  }

  Future<void> cancelActionReminder(int id) {
    return _plugin.cancel(_actionNotificationId(id));
  }

  Future<void> cancelHabitReminder(int id) async {
    await _plugin.cancel(_habitNotificationId(id));
    for (var weekday = DateTime.monday; weekday <= DateTime.friday; weekday++) {
      await _plugin.cancel(_habitWeekdayNotificationId(id, weekday));
    }
  }

  Future<void> _scheduleWeeklyHabitReminder({
    required TrackedHabit habit,
    required int weekday,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) {
    return _plugin.zonedSchedule(
      _habitWeekdayNotificationId(habit.id, weekday),
      title,
      body,
      _nextWeekdayTime(weekday, hour, minute),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'habit:${habit.id}',
    );
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  NotificationDetails _notificationDetails() {
    const android = AndroidNotificationDetails(
      'howlong_reminders',
      'HowLong reminders',
      channelDescription: 'Action and habit reminders from HowLong.',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwin = DarwinNotificationDetails();

    return const NotificationDetails(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );
  }

  tz.TZDateTime _toTzDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  tz.TZDateTime _nextDailyTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextWeekdayTime(int weekday, int hour, int minute) {
    var scheduled = _nextDailyTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  int _actionNotificationId(int id) => 100000 + id;

  int _habitNotificationId(int id) => 200000 + id;

  int _habitWeekdayNotificationId(int id, int weekday) {
    return 300000 + (id * 10) + weekday;
  }
}
