import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/storage_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/primary_action_button.dart';

enum HabitKind { build, breakHabit }

enum HabitSchedule { daily, weekdays, custom }

class AddHabitScreen extends ConsumerStatefulWidget {
  const AddHabitScreen({super.key});

  @override
  ConsumerState<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends ConsumerState<AddHabitScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _goalController =
      TextEditingController(text: '30');
  HabitKind _habitKind = HabitKind.build;
  HabitSchedule _schedule = HabitSchedule.daily;
  bool _reminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  void _leaveScreen() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _saveHabit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);
    final repository = await ref.read(habitsRepositoryProvider.future);
    await repository.addHabit(
      title: title,
      kind: _habitKind.storageValue,
      schedule: _schedule.storageValue,
      targetDays: int.tryParse(_goalController.text.trim()) ?? 30,
      reminderEnabled: _reminderEnabled,
      reminderMinutesAfterMidnight:
          _reminderTime.hour * 60 + _reminderTime.minute,
    );

    if (mounted) {
      _leaveScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _titleController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _AddHabitHeader(onBack: _leaveScreen),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 120),
                physics: const BouncingScrollPhysics(),
                children: [
                  Text(
                    'New Habit',
                    style: AppTextStyles.displayLarge.copyWith(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _habitKind == HabitKind.build
                        ? 'Track a routine you want to keep doing.'
                        : 'Track a streak away from something you want to stop.',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 17,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _FormSection(
                    title: 'Habit',
                    child: TextField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Read 10 pages',
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FormSection(
                    title: 'Type',
                    child: _SegmentedPanel(
                      children: [
                        _ChoiceTile(
                          selected: _habitKind == HabitKind.build,
                          title: 'Build',
                          subtitle: 'Repeat this habit',
                          icon: Icons.eco_rounded,
                          onTap: () =>
                              setState(() => _habitKind = HabitKind.build),
                        ),
                        _ChoiceTile(
                          selected: _habitKind == HabitKind.breakHabit,
                          title: 'Break',
                          subtitle: 'Avoid this habit',
                          icon: Icons.do_not_disturb_on_rounded,
                          onTap: () =>
                              setState(() => _habitKind = HabitKind.breakHabit),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FormSection(
                    title: 'Schedule',
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _ScheduleChip(
                          label: 'Daily',
                          selected: _schedule == HabitSchedule.daily,
                          onSelected: () =>
                              setState(() => _schedule = HabitSchedule.daily),
                        ),
                        _ScheduleChip(
                          label: 'Weekdays',
                          selected: _schedule == HabitSchedule.weekdays,
                          onSelected: () => setState(
                              () => _schedule = HabitSchedule.weekdays),
                        ),
                        _ScheduleChip(
                          label: 'Custom',
                          selected: _schedule == HabitSchedule.custom,
                          onSelected: () =>
                              setState(() => _schedule = HabitSchedule.custom),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FormSection(
                    title: 'Goal',
                    child: TextField(
                      controller: _goalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _habitKind == HabitKind.build
                            ? 'Target streak'
                            : 'Clean streak target',
                        suffixText: 'days',
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FormSection(
                    title: 'Reminder',
                    child: _ReminderTile(
                      enabled: _reminderEnabled,
                      time: _reminderTime,
                      onToggle: (value) =>
                          setState(() => _reminderEnabled = value),
                      onTimeTap: _pickReminderTime,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
          color: AppColors.background,
          child: PrimaryActionButton(
            onPressed: canSave && !_isSaving ? _saveHabit : null,
            icon: Icons.check_rounded,
            label: _isSaving ? 'Saving...' : 'Create Habit',
            isLoading: _isSaving,
          ),
        ),
      ),
    );
  }
}

extension HabitKindStorage on HabitKind {
  String get storageValue {
    return switch (this) {
      HabitKind.build => 'build',
      HabitKind.breakHabit => 'break',
    };
  }
}

extension HabitScheduleStorage on HabitSchedule {
  String get storageValue {
    return switch (this) {
      HabitSchedule.daily => 'daily',
      HabitSchedule.weekdays => 'weekdays',
      HabitSchedule.custom => 'custom',
    };
  }
}

class _AddHabitHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _AddHabitHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const Spacer(),
          Text(
            'HowLong',
            style: AppTextStyles.headingMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _FormSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _SegmentedPanel extends StatelessWidget {
  final List<Widget> children;

  const _SegmentedPanel({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final child in children) Expanded(child: child),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: title == 'Build' ? 8 : 0),
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: const BoxConstraints(minHeight: 116),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.divider,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: selected ? Colors.white : AppColors.primary,
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.captionText.copyWith(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.72)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _ScheduleChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      labelStyle: AppTextStyles.labelLarge.copyWith(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.divider,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final bool enabled;
  final TimeOfDay time;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTimeTap;

  const _ReminderTile({
    required this.enabled,
    required this.time,
    required this.onToggle,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.softSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Check-in reminder',
                  style: AppTextStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: enabled ? onTimeTap : null,
                  child: Text(
                    time.format(context),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color:
                          enabled ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}
