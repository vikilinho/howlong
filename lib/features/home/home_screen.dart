import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/isar_models.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider);
    final habits = ref.watch(habitsProvider);
    final checkIns = ref.watch(habitCheckInsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 116),
          physics: const BouncingScrollPhysics(),
          children: [
            Center(
              child: Text(
                'HowLong',
                style: AppTextStyles.headingLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 34),
            ...switch (_currentIndex) {
              0 => _todayTab(context, events, habits, checkIns),
              1 => _eventsTab(context, events),
              _ => _habitsTab(context, habits, checkIns),
            },
          ].animate(interval: 45.ms).fadeIn(duration: 200.ms).slideY(
                begin: 0.02,
                end: 0,
                duration: 200.ms,
                curve: Curves.easeOutCubic,
              ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today_rounded),
            label: 'TODAY',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'EVENTS',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline_rounded),
            selectedIcon: Icon(Icons.check_circle_rounded),
            label: 'HABITS',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? null
          : FloatingActionButton.extended(
              tooltip: _currentIndex == 1 ? 'Add action' : 'Add habit',
              onPressed: () => context.push(
                _currentIndex == 1 ? '/events/add' : '/habits/add',
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(_currentIndex == 1 ? 'Action' : 'Habit'),
            ),
    );
  }

  List<Widget> _todayTab(
    BuildContext context,
    AsyncValue<List<TrackedEvent>> events,
    AsyncValue<List<TrackedHabit>> habits,
    AsyncValue<List<HabitCheckIn>> checkIns,
  ) {
    return [
      Text(
        'Track the last time.',
        style: AppTextStyles.displayLarge.copyWith(
          fontSize: 38,
          fontWeight: FontWeight.w800,
          height: 1.05,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        'See how long it has been since an action, then log it when you do it again.',
        style: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textSecondary,
          fontSize: 17,
          height: 1.35,
        ),
      ),
      const SizedBox(height: 30),
      _AddRow(
        label: 'Add action',
        onPressed: () => context.push('/events/add'),
      ),
      const SizedBox(height: 12),
      _EventsList(
        events: events,
        limit: 3,
        onLogNow: _logEventNow,
      ),
      const SizedBox(height: 36),
      _AddRow(
        label: 'Add habit',
        onPressed: () => context.push('/habits/add'),
      ),
      const SizedBox(height: 12),
      _HabitsList(
        habits: habits,
        checkIns: checkIns,
        limit: 4,
        hasCheckedInToday: _hasCheckedInToday,
        streakLabel: _streakLabel,
        onCheckIn: _checkInHabit,
      ),
    ];
  }

  List<Widget> _eventsTab(
    BuildContext context,
    AsyncValue<List<TrackedEvent>> events,
  ) {
    return [
      Text(
        'Actions',
        style: AppTextStyles.displayLarge.copyWith(
          fontSize: 38,
          fontWeight: FontWeight.w800,
          height: 1.05,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        'Everything you are tracking by time since last done.',
        style: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textSecondary,
          fontSize: 17,
          height: 1.35,
        ),
      ),
      const SizedBox(height: 30),
      _EventsList(
        events: events,
        onLogNow: _logEventNow,
      ),
    ];
  }

  List<Widget> _habitsTab(
    BuildContext context,
    AsyncValue<List<TrackedHabit>> habits,
    AsyncValue<List<HabitCheckIn>> checkIns,
  ) {
    return [
      Text(
        'Habits',
        style: AppTextStyles.displayLarge.copyWith(
          fontSize: 38,
          fontWeight: FontWeight.w800,
          height: 1.05,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        'All routines and streaks you are building or breaking.',
        style: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textSecondary,
          fontSize: 17,
          height: 1.35,
        ),
      ),
      const SizedBox(height: 30),
      _HabitsList(
        habits: habits,
        checkIns: checkIns,
        hasCheckedInToday: _hasCheckedInToday,
        streakLabel: _streakLabel,
        onCheckIn: _checkInHabit,
      ),
    ];
  }

  Future<void> _logEventNow(TrackedEvent event) async {
    final repository = await ref.read(eventsRepositoryProvider.future);
    await repository.logNow(event);
  }

  Future<void> _checkInHabit(TrackedHabit habit) async {
    final repository = await ref.read(habitsRepositoryProvider.future);
    await repository.checkInToday(habit);
  }

  bool _hasCheckedInToday(TrackedHabit habit, List<HabitCheckIn> checkIns) {
    final now = DateTime.now();
    return checkIns.any((checkIn) {
      return checkIn.habitId == habit.id &&
          checkIn.checkedAt.year == now.year &&
          checkIn.checkedAt.month == now.month &&
          checkIn.checkedAt.day == now.day;
    });
  }

  String _streakLabel(TrackedHabit habit, List<HabitCheckIn> checkIns) {
    final days = checkIns
        .where((checkIn) => checkIn.habitId == habit.id)
        .map((checkIn) => DateTime(
              checkIn.checkedAt.year,
              checkIn.checkedAt.month,
              checkIn.checkedAt.day,
            ))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (days.isEmpty) {
      return '${habit.targetDays} day goal';
    }

    var streak = 0;
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);

    for (final day in days) {
      if (day == cursor) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else if (day == cursor.subtract(const Duration(days: 1)) &&
          streak == 0) {
        streak++;
        cursor = day.subtract(const Duration(days: 1));
      }
    }

    return streak == 1 ? '1 day streak' : '$streak day streak';
  }
}

class _AddRow extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _AddRow({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(label),
        ),
      ],
    );
  }
}

class _EventsList extends StatelessWidget {
  final AsyncValue<List<TrackedEvent>> events;
  final int? limit;
  final Future<void> Function(TrackedEvent event) onLogNow;

  const _EventsList({
    required this.events,
    required this.onLogNow,
    this.limit,
  });

  @override
  Widget build(BuildContext context) {
    return events.when(
      data: (items) {
        if (items.isEmpty) {
          return const _EmptyPanel(
            icon: Icons.history_rounded,
            title: 'No actions yet',
            body: 'Add something you want to track the last time you did.',
          );
        }

        final visibleItems = limit == null ? items : items.take(limit!);
        return Column(
          children: [
            for (final event in visibleItems) ...[
              _SinceCard(
                event: event,
                onLogNow: () => onLogNow(event),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
      error: (error, _) => _ErrorPanel(message: error.toString()),
      loading: () => const _LoadingPanel(),
    );
  }
}

class _HabitsList extends StatelessWidget {
  final AsyncValue<List<TrackedHabit>> habits;
  final AsyncValue<List<HabitCheckIn>> checkIns;
  final int? limit;
  final bool Function(TrackedHabit habit, List<HabitCheckIn> checkIns)
      hasCheckedInToday;
  final String Function(TrackedHabit habit, List<HabitCheckIn> checkIns)
      streakLabel;
  final Future<void> Function(TrackedHabit habit) onCheckIn;

  const _HabitsList({
    required this.habits,
    required this.checkIns,
    required this.hasCheckedInToday,
    required this.streakLabel,
    required this.onCheckIn,
    this.limit,
  });

  @override
  Widget build(BuildContext context) {
    return habits.when(
      data: (items) {
        final logs = checkIns.valueOrNull ?? const <HabitCheckIn>[];
        if (items.isEmpty) {
          return const _EmptyPanel(
            icon: Icons.check_circle_outline_rounded,
            title: 'No habits yet',
            body: 'Add a habit to track today and build a streak.',
          );
        }

        final visibleItems = limit == null ? items : items.take(limit!);
        return Column(
          children: [
            for (final habit in visibleItems) ...[
              _HabitCard(
                habit: habit,
                completed: hasCheckedInToday(habit, logs),
                streakLabel: streakLabel(habit, logs),
                onCheckIn: () => onCheckIn(habit),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
      error: (error, _) => _ErrorPanel(message: error.toString()),
      loading: () => const _LoadingPanel(),
    );
  }
}

class _SinceCard extends StatelessWidget {
  final TrackedEvent event;
  final VoidCallback onLogNow;

  const _SinceCard({
    required this.event,
    required this.onLogNow,
  });

  @override
  Widget build(BuildContext context) {
    final elapsedDuration = DateTime.now().difference(event.lastPerformedAt);
    final reminderDuration = _reminderDuration(event);
    final isOverdue =
        reminderDuration != null && elapsedDuration > reminderDuration;
    final elapsed = _elapsedLabel(event.lastPerformedAt);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: isOverdue
              ? AppColors.error.withValues(alpha: 0.35)
              : AppColors.divider,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(icon: icon),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: onLogNow,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(58, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('Log'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            elapsed,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.displayMedium.copyWith(
              color: isOverdue ? AppColors.error : AppColors.primary,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isOverdue
                ? 'Overdue by ${_durationLabel(elapsedDuration - reminderDuration)}'
                : 'Last logged ${_dateLabel(event.lastPerformedAt)}',
            maxLines: 2,
            overflow: TextOverflow.visible,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isOverdue ? AppColors.error : AppColors.textSecondary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  IconData get icon {
    return switch (event.category) {
      'Car' => Icons.local_gas_station_outlined,
      'Home' => Icons.home_outlined,
      'Health' => Icons.favorite_border_rounded,
      _ => Icons.history_rounded,
    };
  }

  String _elapsedLabel(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays >= 1) {
      return difference.inDays == 1
          ? '1 day ago'
          : '${difference.inDays} days ago';
    }
    if (difference.inHours >= 1) {
      return difference.inHours == 1
          ? '1 hour ago'
          : '${difference.inHours} hours ago';
    }
    if (difference.inMinutes >= 1) {
      return difference.inMinutes == 1
          ? '1 minute ago'
          : '${difference.inMinutes} minutes ago';
    }
    return 'just now';
  }

  String _dateLabel(DateTime date) {
    final time = TimeOfDay.fromDateTime(date);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} at $hour:$minute $period';
  }

  Duration? _reminderDuration(TrackedEvent event) {
    final value = event.reminderAfterValue;
    if (value == null || value <= 0) return null;

    return switch (event.reminderAfterUnit) {
      'minutes' => Duration(minutes: value),
      'hours' => Duration(hours: value),
      'days' => Duration(days: value),
      'weeks' => Duration(days: value * 7),
      'months' => Duration(days: value * 30),
      _ => Duration(days: value),
    };
  }

  String _durationLabel(Duration duration) {
    if (duration.inDays >= 60) {
      final months = duration.inDays ~/ 30;
      return months == 1 ? '1 month' : '$months months';
    }
    if (duration.inDays >= 14) {
      final weeks = duration.inDays ~/ 7;
      return weeks == 1 ? '1 week' : '$weeks weeks';
    }
    if (duration.inDays >= 1) {
      return duration.inDays == 1 ? '1 day' : '${duration.inDays} days';
    }
    if (duration.inHours >= 1) {
      return duration.inHours == 1 ? '1 hour' : '${duration.inHours} hours';
    }
    final minutes = duration.inMinutes.clamp(1, 59);
    return minutes == 1 ? '1 minute' : '$minutes minutes';
  }
}

class _HabitCard extends StatelessWidget {
  final TrackedHabit habit;
  final bool completed;
  final String streakLabel;
  final VoidCallback onCheckIn;

  const _HabitCard({
    required this.habit,
    required this.completed,
    required this.streakLabel,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: completed ? AppColors.softSurface : AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: completed ? AppColors.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: completed
                  ? null
                  : Border.all(color: AppColors.textPrimary, width: 2.2),
            ),
            child: Icon(
              completed ? Icons.check_rounded : icon,
              color: completed ? Colors.white : AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingMedium.copyWith(
                    decoration: completed ? TextDecoration.lineThrough : null,
                    color: completed
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  habit.kind == 'break' ? 'Break habit' : 'Build habit',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                height: 34,
                child: FilledButton(
                  onPressed: completed ? null : onCheckIn,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: Text(completed ? 'Done' : 'Check in'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                streakLabel,
                style: AppTextStyles.captionText.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData get icon {
    return habit.kind == 'break'
        ? Icons.do_not_disturb_on_rounded
        : Icons.eco_rounded;
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _IconBadge(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  body,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;

  const _ErrorPanel({required this.message});

  @override
  Widget build(BuildContext context) {
    return _EmptyPanel(
      icon: Icons.error_outline_rounded,
      title: 'Could not load',
      body: message,
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;

  const _IconBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.softSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.primary),
    );
  }
}
