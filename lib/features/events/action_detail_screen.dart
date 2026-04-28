import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/isar_models.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class ActionDetailScreen extends ConsumerWidget {
  final int actionId;

  const ActionDetailScreen({
    super.key,
    required this.actionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: events.when(
          data: (items) {
            final event =
                items.where((item) => item.id == actionId).firstOrNull;
            if (event == null) {
              return const _MissingDetail(message: 'Action not found');
            }
            return _ActionDetailContent(event: event);
          },
          error: (error, _) => _MissingDetail(message: error.toString()),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _ActionDetailContent extends ConsumerWidget {
  final TrackedEvent event;

  const _ActionDetailContent({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elapsedDuration = DateTime.now().difference(event.lastPerformedAt);
    final reminderDuration = _reminderDuration(event);
    final nextReminder = reminderDuration == null
        ? null
        : event.lastPerformedAt.add(reminderDuration);
    final isOverdue =
        reminderDuration != null && elapsedDuration > reminderDuration;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      physics: const BouncingScrollPhysics(),
      children: [
        _DetailHeader(
          title: event.title,
          icon: _iconForCategory(event.category),
          onBack: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(height: 28),
        Text(
          _elapsedLabel(event.lastPerformedAt),
          style: AppTextStyles.timeSinceHero.copyWith(
            color: isOverdue ? AppColors.error : AppColors.primary,
            fontSize: 42,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isOverdue
              ? 'Overdue by ${_durationLabel(elapsedDuration - reminderDuration)}'
              : 'Since this was last logged',
          style: AppTextStyles.bodyLarge.copyWith(
            color: isOverdue ? AppColors.error : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: () async {
            final repository = await ref.read(eventsRepositoryProvider.future);
            await repository.logNow(event);
          },
          icon: const Icon(Icons.add_task_rounded),
          label: const Text('Log now'),
        ),
        const SizedBox(height: 28),
        _InfoGrid(
          children: [
            _InfoTile(
              icon: Icons.category_outlined,
              label: 'Category',
              value: event.category,
            ),
            _InfoTile(
              icon: Icons.notifications_none_rounded,
              label: 'Reminder',
              value: _reminderLabel(event),
            ),
            _InfoTile(
              icon: Icons.history_rounded,
              label: 'Last logged',
              value: _dateTimeLabel(event.lastPerformedAt),
            ),
            _InfoTile(
              icon: Icons.schedule_rounded,
              label: 'Next reminder',
              value:
                  nextReminder == null ? 'Off' : _dateTimeLabel(nextReminder),
            ),
          ],
        ),
        if (event.note != null) ...[
          const SizedBox(height: 18),
          _NotePanel(note: event.note!),
        ],
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
          Text(
            label,
            style: AppTextStyles.bodySmall,
          ),
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

class _NotePanel extends StatelessWidget {
  final String note;

  const _NotePanel({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Note', style: AppTextStyles.headingSmall),
          const SizedBox(height: 8),
          Text(
            note,
            style: AppTextStyles.bodyMedium.copyWith(height: 1.35),
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

IconData _iconForCategory(String category) {
  return switch (category) {
    'Car' => Icons.local_gas_station_outlined,
    'Home' => Icons.home_outlined,
    'Health' => Icons.favorite_border_rounded,
    _ => Icons.history_rounded,
  };
}

Duration? _reminderDuration(TrackedEvent event) {
  final value = event.reminderAfterValue;
  if (value == null || value <= 0) return null;

  return switch (event.reminderAfterUnit) {
    'minutes' => Duration(minutes: value),
    'hours' => Duration(hours: value),
    'weeks' => Duration(days: value * 7),
    'months' => Duration(days: value * 30),
    _ => Duration(days: value),
  };
}

String _reminderLabel(TrackedEvent event) {
  final value = event.reminderAfterValue;
  if (value == null || value <= 0) return 'Off';
  final unit = value == 1
      ? event.reminderAfterUnit.replaceAll(RegExp("s\$"), '')
      : event.reminderAfterUnit;
  return 'Every $value $unit';
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

String _dateTimeLabel(DateTime date) {
  final time = TimeOfDay.fromDateTime(date);
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} $hour:$minute $period';
}
