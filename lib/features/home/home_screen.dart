import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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
  bool _isScrolling = false;

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider);
    final habits = ref.watch(habitsProvider);
    final checkIns = ref.watch(habitCheckInsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
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

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification ||
        notification is OverscrollNotification) {
      if (!_isScrolling) {
        setState(() => _isScrolling = true);
      }
    } else if (notification is ScrollEndNotification && _isScrolling) {
      setState(() => _isScrolling = false);
    }
    return false;
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
        isScrolling: _isScrolling,
        onOpen: _openEvent,
        onLogNow: _logEventNow,
        onDelete: _deleteEvent,
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
        isScrolling: _isScrolling,
        onOpen: _openHabit,
        hasCheckedInToday: _hasCheckedInToday,
        streakLabel: _streakLabel,
        onCheckIn: _checkInHabit,
        onDelete: _deleteHabit,
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
        isScrolling: _isScrolling,
        onOpen: _openEvent,
        onLogNow: _logEventNow,
        onDelete: _deleteEvent,
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
        isScrolling: _isScrolling,
        onOpen: _openHabit,
        hasCheckedInToday: _hasCheckedInToday,
        streakLabel: _streakLabel,
        onCheckIn: _checkInHabit,
        onDelete: _deleteHabit,
      ),
    ];
  }

  Future<void> _logEventNow(TrackedEvent event) async {
    final repository = await ref.read(eventsRepositoryProvider.future);
    await repository.logNow(event);
  }

  void _openEvent(TrackedEvent event) {
    context.push('/events/${event.id}');
  }

  void _openHabit(TrackedHabit habit) {
    context.push('/habits/${habit.id}');
  }

  Future<void> _deleteEvent(TrackedEvent event) async {
    final repository = await ref.read(eventsRepositoryProvider.future);
    await repository.deleteEvent(event.id);
  }

  Future<void> _checkInHabit(TrackedHabit habit) async {
    final repository = await ref.read(habitsRepositoryProvider.future);
    await repository.checkInToday(habit);
  }

  Future<void> _deleteHabit(TrackedHabit habit) async {
    final repository = await ref.read(habitsRepositoryProvider.future);
    await repository.deleteHabit(habit.id);
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
  final bool isScrolling;
  final void Function(TrackedEvent event) onOpen;
  final Future<void> Function(TrackedEvent event) onLogNow;
  final Future<void> Function(TrackedEvent event) onDelete;

  const _EventsList({
    required this.events,
    required this.isScrolling,
    required this.onOpen,
    required this.onLogNow,
    required this.onDelete,
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

        final visibleItems =
            (limit == null ? items : items.take(limit!)).toList();
        return Column(
          children: [
            for (var index = 0; index < visibleItems.length; index++) ...[
              _SinceCard(
                event: visibleItems[index],
                animationIndex: index,
                isScrolling: isScrolling,
                onOpen: () => onOpen(visibleItems[index]),
                onLogNow: () => onLogNow(visibleItems[index]),
                onDelete: () => onDelete(visibleItems[index]),
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
  final bool isScrolling;
  final void Function(TrackedHabit habit) onOpen;
  final bool Function(TrackedHabit habit, List<HabitCheckIn> checkIns)
      hasCheckedInToday;
  final String Function(TrackedHabit habit, List<HabitCheckIn> checkIns)
      streakLabel;
  final Future<void> Function(TrackedHabit habit) onCheckIn;
  final Future<void> Function(TrackedHabit habit) onDelete;

  const _HabitsList({
    required this.habits,
    required this.checkIns,
    required this.isScrolling,
    required this.onOpen,
    required this.hasCheckedInToday,
    required this.streakLabel,
    required this.onCheckIn,
    required this.onDelete,
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

        final visibleItems =
            (limit == null ? items : items.take(limit!)).toList();
        return Column(
          children: [
            for (var index = 0; index < visibleItems.length; index++) ...[
              _HabitCard(
                habit: visibleItems[index],
                animationIndex: index,
                isScrolling: isScrolling,
                onOpen: () => onOpen(visibleItems[index]),
                completed: hasCheckedInToday(visibleItems[index], logs),
                streakLabel: streakLabel(visibleItems[index], logs),
                onCheckIn: () => onCheckIn(visibleItems[index]),
                onDelete: () => onDelete(visibleItems[index]),
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
  final int animationIndex;
  final bool isScrolling;
  final VoidCallback onOpen;
  final VoidCallback onLogNow;
  final VoidCallback onDelete;

  const _SinceCard({
    required this.event,
    required this.animationIndex,
    required this.isScrolling,
    required this.onOpen,
    required this.onLogNow,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final elapsedDuration = DateTime.now().difference(event.lastPerformedAt);
    final reminderDuration = _reminderDuration(event);
    final isOverdue =
        reminderDuration != null && elapsedDuration > reminderDuration;
    final elapsed = _elapsedLabel(event.lastPerformedAt);

    return Slidable(
      key: ValueKey(event.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            borderRadius: BorderRadius.circular(18),
          ),
        ],
      ),
      child: _ScrollScaleCard(
        isScrolling: isScrolling,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: 220.ms,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(
                color: isOverdue
                    ? AppColors.error.withValues(alpha: 0.35)
                    : AppColors.divider,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
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
                    _AnimatedActionButton(
                      label: 'Log',
                      icon: Icons.add_task_rounded,
                      onPressed: onLogNow,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AnimatedDefaultTextStyle(
                  duration: 220.ms,
                  curve: Curves.easeOutCubic,
                  style: AppTextStyles.displayMedium.copyWith(
                    color: isOverdue ? AppColors.error : AppColors.primary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                  child: Text(
                    elapsed,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isOverdue) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Overdue by ${_durationLabel(elapsedDuration - reminderDuration)}',
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    )
        .animate(key: ValueKey('event-card-${event.id}'))
        .fadeIn(delay: (animationIndex * 45).ms, duration: 260.ms)
        .slideY(
          begin: 0.05,
          end: 0,
          delay: (animationIndex * 45).ms,
          duration: 260.ms,
          curve: Curves.easeOutCubic,
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
  final int animationIndex;
  final bool isScrolling;
  final VoidCallback onOpen;
  final bool completed;
  final String streakLabel;
  final VoidCallback onCheckIn;
  final VoidCallback onDelete;

  const _HabitCard({
    required this.habit,
    required this.animationIndex,
    required this.isScrolling,
    required this.onOpen,
    required this.completed,
    required this.streakLabel,
    required this.onCheckIn,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(habit.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            borderRadius: BorderRadius.circular(18),
          ),
        ],
      ),
      child: _ScrollScaleCard(
        isScrolling: isScrolling,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: 240.ms,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: completed ? AppColors.softSurface : AppColors.surface,
              border: Border.all(
                color: completed
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : AppColors.divider,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary
                      .withValues(alpha: completed ? 0.08 : 0.05),
                  blurRadius: completed ? 24 : 18,
                  offset: const Offset(0, 10),
                ),
              ],
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: 240.ms,
                  curve: Curves.easeOutBack,
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: completed ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: completed
                        ? null
                        : Border.all(color: AppColors.textPrimary, width: 2.2),
                  ),
                  child: AnimatedSwitcher(
                    duration: 220.ms,
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: Icon(
                      completed ? Icons.check_rounded : icon,
                      key: ValueKey(completed ? 'done' : habit.kind),
                      color: completed ? Colors.white : AppColors.primary,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: 180.ms,
                        style: AppTextStyles.headingMedium.copyWith(
                          decoration:
                              completed ? TextDecoration.lineThrough : null,
                          color: completed
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                        child: Text(
                          habit.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                    _AnimatedActionButton(
                      label: completed ? 'Done' : 'Check in',
                      icon: completed
                          ? Icons.check_rounded
                          : Icons.radio_button_unchecked_rounded,
                      onPressed: completed ? null : onCheckIn,
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
          ),
        ),
      ),
    )
        .animate(key: ValueKey('habit-card-${habit.id}-$completed'))
        .fadeIn(delay: (animationIndex * 45).ms, duration: 260.ms)
        .slideY(
          begin: 0.05,
          end: 0,
          delay: (animationIndex * 45).ms,
          duration: 260.ms,
          curve: Curves.easeOutCubic,
        );
  }

  IconData get icon {
    return habit.kind == 'break'
        ? Icons.do_not_disturb_on_rounded
        : Icons.eco_rounded;
  }
}

class _ScrollScaleCard extends StatelessWidget {
  final Widget child;
  final bool isScrolling;

  const _ScrollScaleCard({
    required this.child,
    required this.isScrolling,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isScrolling ? 0.975 : 1,
      duration: isScrolling ? 140.ms : 220.ms,
      curve: Curves.easeOutCubic,
      child: child,
    );
  }
}

class _AnimatedActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _AnimatedActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: onPressed == null ? 0.62 : 1,
      duration: 180.ms,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: AnimatedSwitcher(
          duration: 180.ms,
          child: Icon(icon, key: ValueKey(icon), size: 18),
        ),
        label: AnimatedSwitcher(
          duration: 180.ms,
          child: Text(label, key: ValueKey(label)),
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size(58, 34),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
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
