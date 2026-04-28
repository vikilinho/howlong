import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import 'isar_models.dart';
import 'isar_service.dart';
import 'repositories.dart';

final isarProvider = FutureProvider<Isar>((ref) {
  return IsarService.instance;
});

final eventsRepositoryProvider = FutureProvider<EventsRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return EventsRepository(isar);
});

final habitsRepositoryProvider = FutureProvider<HabitsRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return HabitsRepository(isar);
});

final eventsProvider = StreamProvider<List<TrackedEvent>>((ref) async* {
  final repository = await ref.watch(eventsRepositoryProvider.future);
  yield* repository.watchEvents();
});

final habitsProvider = StreamProvider<List<TrackedHabit>>((ref) async* {
  final repository = await ref.watch(habitsRepositoryProvider.future);
  yield* repository.watchHabits();
});

final habitCheckInsProvider = StreamProvider<List<HabitCheckIn>>((ref) async* {
  final repository = await ref.watch(habitsRepositoryProvider.future);
  yield* repository.watchCheckIns();
});
