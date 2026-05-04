import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/isar_models.dart';
import '../../core/storage/repositories.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/primary_action_button.dart';

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
    final streakBroken = isStreakBroken(habitCheckIns, habit.schedule);
    final activeCheckIns =
        streakBroken ? const <HabitCheckIn>[] : habitCheckIns;
    final streak = _streakCount(activeCheckIns);
    final needsRestart = streakBroken && !checkedInToday;

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
          onEdit: () => context.push('/habits/${habit.id}/edit'),
          onDelete: () => _confirmDeleteHabit(context, ref),
        ),
        const SizedBox(height: 22),
        Text(
          needsRestart
              ? 'Restart streak'
              : streak == 0
                  ? 'Start today'
                  : streak == 1
                      ? '1 day strong'
                      : '$streak days strong',
          style: AppTextStyles.streakHero.copyWith(
            color: AppColors.primary,
            fontSize: 36,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          needsRestart
              ? 'Your previous streak ended. Start again with a clean count.'
              : habit.kind == 'break'
                  ? 'Keep protecting the pattern you are breaking.'
                  : 'Keep building the rhythm one check-in at a time.',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.flag_rounded,
                label: 'Current goal',
                value: '${habit.targetDays} days',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _SummaryCard(
                icon: Icons.done_all_rounded,
                label: 'Total logged',
                value: '${activeCheckIns.length} times',
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _GoalProgressCard(
          streak: streak,
          target: habit.targetDays,
        ),
        const SizedBox(height: 18),
        _DetailInfoCard(
          type: habit.kind == 'break' ? 'Break habit' : 'Build habit',
          schedule: _scheduleLabel(habit.schedule),
          reminder: _reminderLabel(habit),
        ),
        const SizedBox(height: 26),
        PrimaryActionButton(
          onPressed: checkedInToday
              ? null
              : () async {
                  final repository =
                      await ref.read(habitsRepositoryProvider.future);
                  await repository.checkInToday(habit);
                },
          icon: checkedInToday ? Icons.check_rounded : Icons.add_task_rounded,
          label: checkedInToday
              ? 'Done today'
              : needsRestart
                  ? 'Restart streak'
                  : 'Log today',
        ),
      ],
    );
  }

  Future<void> _confirmDeleteHabit(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showDeleteDialog(
      context: context,
      title: 'Delete habit?',
      body: 'This removes "${habit.title}" and its check-ins.',
    );
    if (!confirmed) return;

    final repository = await ref.read(habitsRepositoryProvider.future);
    await repository.deleteHabit(habit.id);

    if (context.mounted) {
      context.go('/home');
    }
  }
}

class _DetailHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DetailHeader({
    required this.title,
    required this.icon,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Edit habit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Delete habit',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.error.withValues(alpha: 0.08),
                foregroundColor: AppColors.error,
              ),
            ),
          ],
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

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 138),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 24),
          const SizedBox(height: 26),
          Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.displayMedium.copyWith(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.12,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalProgressCard extends StatelessWidget {
  final int streak;
  final int target;

  const _GoalProgressCard({
    required this.streak,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final rhythmTarget = _rhythmTarget(streak: streak, target: target);
    final progress =
        rhythmTarget > 0 ? (streak / rhythmTarget).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consistency rhythm',
            style: AppTextStyles.labelLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$percent%',
            style: AppTextStyles.streakHero.copyWith(
              color: Colors.white,
              fontSize: 54,
              height: 1,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.accent.withValues(alpha: 0.92),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$streak of $rhythmTarget days in this rhythm',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.68),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$rhythmTarget of $target day goal',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.68),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailInfoCard extends StatelessWidget {
  final String type;
  final String schedule;
  final String reminder;

  const _DetailInfoCard({
    required this.type,
    required this.schedule,
    required this.reminder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _DetailInfoRow(
            icon: Icons.spa_outlined,
            label: 'Type',
            value: type,
          ),
          const Divider(height: 24, color: AppColors.divider),
          _DetailInfoRow(
            icon: Icons.event_repeat_rounded,
            label: 'Schedule',
            value: schedule,
          ),
          const Divider(height: 24, color: AppColors.divider),
          _DetailInfoRow(
            icon: Icons.notifications_none_rounded,
            label: 'Reminder',
            value: reminder,
          ),
        ],
      ),
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.softSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
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

int _rhythmTarget({
  required int streak,
  required int target,
}) {
  if (target <= 0) return 0;
  if (streak >= target) return target;

  final completedWeeks = streak ~/ 7;
  final nextCheckpoint = (completedWeeks + 1) * 7;
  return nextCheckpoint.clamp(1, target);
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

Future<bool> _showDeleteDialog({
  required BuildContext context,
  required String title,
  required String body,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
