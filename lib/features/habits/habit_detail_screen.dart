import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/isar_models.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class HabitDetailScreen extends ConsumerWidget {
  final int habitId;

  const HabitDetailScreen({
    super.key,
    required this.habitId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    final checkIns = ref.watch(habitCheckInsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: habits.when(
          data: (items) {
            final habit = items.where((item) => item.id == habitId).firstOrNull;
            if (habit == null) {
              return const _MissingDetail(message: 'Habit not found');
            }
            return _HabitDetailContent(
              habit: habit,
              checkIns: checkIns.valueOrNull ?? const <HabitCheckIn>[],
            );
          },
          error: (error, _) => _MissingDetail(message: error.toString()),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _HabitDetailContent extends ConsumerWidget {
  final TrackedHabit habit;
  final List<HabitCheckIn> checkIns;

  const _HabitDetailContent({
    required this.habit,
    required this.checkIns,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitCheckIns = checkIns
        .where((checkIn) => checkIn.habitId == habit.id)
        .toList()
      ..sort((a, b) => b.checkedAt.compareTo(a.checkedAt));
    final checkedInToday = _hasCheckedInToday(habitCheckIns);
    final streak = _streakCount(habitCheckIns);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      physics: const BouncingScrollPhysics(),
      children: [
        _DetailHeader(
          title: habit.title,
          icon: habit.kind == 'break'
              ? Icons.do_not_disturb_on_rounded
              : Icons.eco_rounded,
          onBack: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(height: 28),
        Text(
          streak == 1 ? '1 day' : '$streak days',
          style: AppTextStyles.streakHero.copyWith(
            color: AppColors.primary,
            fontSize: 46,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          streak == 0 ? 'No streak yet' : 'Current streak',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: checkedInToday
              ? null
              : () async {
                  final repository =
                      await ref.read(habitsRepositoryProvider.future);
                  await repository.checkInToday(habit);
                },
          icon: Icon(checkedInToday
              ? Icons.check_rounded
              : Icons.radio_button_unchecked_rounded),
          label: Text(checkedInToday ? 'Done today' : 'Check in today'),
        ),
        const SizedBox(height: 28),
        _InfoGrid(
          children: [
            _InfoTile(
              icon: Icons.flag_outlined,
              label: 'Goal',
              value: '${habit.targetDays} days',
            ),
            _InfoTile(
              icon: Icons.spa_outlined,
              label: 'Type',
              value: habit.kind == 'break' ? 'Break habit' : 'Build habit',
            ),
            _InfoTile(
              icon: Icons.event_repeat_rounded,
              label: 'Schedule',
              value: _scheduleLabel(habit.schedule),
            ),
            _InfoTile(
              icon: Icons.notifications_none_rounded,
              label: 'Reminder',
              value: _reminderLabel(habit),
            ),
            _InfoTile(
              icon: Icons.fact_check_outlined,
              label: 'Total check-ins',
              value: '${habitCheckIns.length}',
            ),
            _InfoTile(
              icon: Icons.history_rounded,
              label: 'Last check-in',
              value: habitCheckIns.isEmpty
                  ? 'None yet'
                  : _dateTimeLabel(habitCheckIns.first.checkedAt),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onBack;

  const _DetailHeader({
    required this.title,
    required this.icon,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: AppColors.softSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
          ),
          child: Icon(icon, color: AppColors.primary, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: AppTextStyles.displayLarge.copyWith(
            fontSize: 38,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final List<Widget> children;

  const _InfoGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const Spacer(),
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingDetail extends StatelessWidget {
  final String message;

  const _MissingDetail({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, style: AppTextStyles.bodyLarge),
    );
  }
}

bool _hasCheckedInToday(List<HabitCheckIn> checkIns) {
  final now = DateTime.now();
  return checkIns.any((checkIn) {
    return checkIn.checkedAt.year == now.year &&
        checkIn.checkedAt.month == now.month &&
        checkIn.checkedAt.day == now.day;
  });
}

int _streakCount(List<HabitCheckIn> checkIns) {
  final days = checkIns
      .map((checkIn) => DateTime(
            checkIn.checkedAt.year,
            checkIn.checkedAt.month,
            checkIn.checkedAt.day,
          ))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));

  var streak = 0;
  var cursor = DateTime.now();
  cursor = DateTime(cursor.year, cursor.month, cursor.day);

  for (final day in days) {
    if (day == cursor) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    } else if (day == cursor.subtract(const Duration(days: 1)) && streak == 0) {
      streak++;
      cursor = day.subtract(const Duration(days: 1));
    }
  }

  return streak;
}

String _scheduleLabel(String schedule) {
  return switch (schedule) {
    'weekdays' => 'Weekdays',
    'custom' => 'Custom',
    _ => 'Daily',
  };
}

String _reminderLabel(TrackedHabit habit) {
  if (!habit.reminderEnabled) return 'Off';
  final minutes = habit.reminderMinutesAfterMidnight;
  if (minutes == null) return 'Off';
  final hour24 = minutes ~/ 60;
  final minute = minutes % 60;
  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour = hour24 % 12 == 0 ? 12 : hour24 % 12;
  return '$hour:${minute.toString().padLeft(2, '0')} $period';
}

String _dateTimeLabel(DateTime date) {
  final time = TimeOfDay.fromDateTime(date);
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} $hour:$minute $period';
}
