import 'package:isar_community/isar.dart';

part 'isar_models.g.dart';

@collection
class TrackedEvent {
  Id id = Isar.autoIncrement;

  late String title;
  late String category;
  late DateTime lastPerformedAt;

  int? reminderAfterValue;
  String reminderAfterUnit = 'days';
  String? note;

  late DateTime createdAt;
  late DateTime updatedAt;
}

@collection
class TrackedHabit {
  Id id = Isar.autoIncrement;

  late String title;
  late String kind;
  late String schedule;
  late int targetDays;

  bool reminderEnabled = true;
  int? reminderMinutesAfterMidnight;

  late DateTime createdAt;
  late DateTime updatedAt;
}

@collection
class HabitCheckIn {
  Id id = Isar.autoIncrement;

  late int habitId;
  late DateTime checkedAt;
}
