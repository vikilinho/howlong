import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/isar_models.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/primary_action_button.dart';

enum EventCategory { car, home, health, personal }

enum ReminderUnit { minutes, hours, days, weeks, months }

class AddEventScreen extends ConsumerStatefulWidget {
  final TrackedEvent? event;

  const AddEventScreen({
    super.key,
    this.event,
  });

  @override
  ConsumerState<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends ConsumerState<AddEventScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _reminderController =
      TextEditingController(text: '7');
  final TextEditingController _noteController = TextEditingController();
  EventCategory _category = EventCategory.car;
  ReminderUnit _reminderUnit = ReminderUnit.days;
  DateTime _lastPerformedAt = DateTime.now();
  bool _reminderEnabled = true;
  bool _isSaving = false;
  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    if (event == null) return;

    _titleController.text = event.title;
    _noteController.text = event.note ?? '';
    _reminderController.text = (event.reminderAfterValue ?? 7).toString();
    _category = EventCategoryX.fromLabel(event.category);
    _reminderUnit = ReminderUnitX.fromStorageValue(event.reminderAfterUnit);
    _lastPerformedAt = event.lastPerformedAt;
    _reminderEnabled =
        event.reminderAfterValue != null && event.reminderAfterValue! > 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _reminderController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _leaveScreen() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _pickLastPerformedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPerformedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _lastPerformedAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _lastPerformedAt.hour,
          _lastPerformedAt.minute,
        );
      });
    }
  }

  Future<void> _pickLastPerformedTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_lastPerformedAt),
    );
    if (picked != null) {
      setState(() {
        _lastPerformedAt = DateTime(
          _lastPerformedAt.year,
          _lastPerformedAt.month,
          _lastPerformedAt.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _saveEvent() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final repository = await ref.read(eventsRepositoryProvider.future);
      final reminderValue = _reminderEnabled
          ? int.tryParse(_reminderController.text.trim())
          : null;

      final event = widget.event;
      if (event == null) {
        await repository.addEvent(
          title: title,
          category: _category.label,
          lastPerformedAt: _lastPerformedAt,
          reminderAfterValue: reminderValue,
          reminderAfterUnit: _reminderUnit.storageValue,
          note: _noteController.text,
        );
      } else {
        await repository.updateEvent(
          event,
          title: title,
          category: _category.label,
          lastPerformedAt: _lastPerformedAt,
          reminderAfterValue: reminderValue,
          reminderAfterUnit: _reminderUnit.storageValue,
          note: _noteController.text,
        );
      }

      if (mounted) {
        _leaveScreen();
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to save action "$title": $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this action. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
            _InputHeader(onBack: _leaveScreen),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 120),
                physics: const BouncingScrollPhysics(),
                children: [
                  Text(
                    _isEditing ? 'Edit Action' : 'New Action',
                    style: AppTextStyles.displayLarge.copyWith(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Track the last time you did something, then reset the clock when you do it again.',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 17,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _FormSection(
                    title: 'Action',
                    child: TextField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Fuelled car',
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FormSection(
                    title: 'Category',
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _CategoryChip(
                          label: 'Car',
                          icon: Icons.directions_car_outlined,
                          selected: _category == EventCategory.car,
                          onSelected: () =>
                              setState(() => _category = EventCategory.car),
                        ),
                        _CategoryChip(
                          label: 'Home',
                          icon: Icons.home_outlined,
                          selected: _category == EventCategory.home,
                          onSelected: () =>
                              setState(() => _category = EventCategory.home),
                        ),
                        _CategoryChip(
                          label: 'Health',
                          icon: Icons.favorite_border_rounded,
                          selected: _category == EventCategory.health,
                          onSelected: () =>
                              setState(() => _category = EventCategory.health),
                        ),
                        _CategoryChip(
                          label: 'Personal',
                          icon: Icons.person_outline_rounded,
                          selected: _category == EventCategory.personal,
                          onSelected: () => setState(
                              () => _category = EventCategory.personal),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FormSection(
                    title: 'Last Performed',
                    child: _DateTimeTile(
                      dateTime: _lastPerformedAt,
                      onDateTap: _pickLastPerformedDate,
                      onTimeTap: _pickLastPerformedTime,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FormSection(
                    title: 'Reminder',
                    child: _ReminderThresholdTile(
                      enabled: _reminderEnabled,
                      controller: _reminderController,
                      unit: _reminderUnit,
                      onUnitChanged: (unit) =>
                          setState(() => _reminderUnit = unit),
                      onToggle: (value) =>
                          setState(() => _reminderEnabled = value),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FormSection(
                    title: 'Note',
                    child: TextField(
                      controller: _noteController,
                      minLines: 3,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Optional',
                        hintText: 'Anything useful to remember?',
                      ),
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
            onPressed: canSave && !_isSaving ? _saveEvent : null,
            icon: Icons.check_rounded,
            label: _isSaving
                ? 'Saving...'
                : _isEditing
                    ? 'Save Changes'
                    : 'Create Action',
            isLoading: _isSaving,
          ),
        ),
      ),
    );
  }
}

extension ReminderUnitText on ReminderUnit {
  String get label {
    return switch (this) {
      ReminderUnit.minutes => 'Minutes',
      ReminderUnit.hours => 'Hours',
      ReminderUnit.days => 'Days',
      ReminderUnit.weeks => 'Weeks',
      ReminderUnit.months => 'Months',
    };
  }

  String get storageValue {
    return switch (this) {
      ReminderUnit.minutes => 'minutes',
      ReminderUnit.hours => 'hours',
      ReminderUnit.days => 'days',
      ReminderUnit.weeks => 'weeks',
      ReminderUnit.months => 'months',
    };
  }
}

extension ReminderUnitX on ReminderUnit {
  static ReminderUnit fromStorageValue(String value) {
    return ReminderUnit.values.firstWhere(
      (unit) => unit.storageValue == value,
      orElse: () => ReminderUnit.days,
    );
  }
}

extension EventCategoryLabel on EventCategory {
  String get label {
    return switch (this) {
      EventCategory.car => 'Car',
      EventCategory.home => 'Home',
      EventCategory.health => 'Health',
      EventCategory.personal => 'Personal',
    };
  }
}

extension EventCategoryX on EventCategory {
  static EventCategory fromLabel(String label) {
    return EventCategory.values.firstWhere(
      (category) => category.label.toLowerCase() == label.toLowerCase(),
      orElse: () => EventCategory.personal,
    );
  }
}

class _InputHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _InputHeader({required this.onBack});

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

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? Colors.white : AppColors.primary,
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  final DateTime dateTime;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;

  const _DateTimeTile({
    required this.dateTime,
    required this.onDateTap,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    final formattedTime = TimeOfDay.fromDateTime(dateTime).format(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _PickerRow(
            icon: Icons.event_rounded,
            title: formattedDate,
            subtitle: 'Date',
            onTap: onDateTap,
          ),
          const Divider(height: 24),
          _PickerRow(
            icon: Icons.schedule_rounded,
            title: formattedTime,
            subtitle: 'Time',
            onTap: onTimeTap,
          ),
        ],
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PickerRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.softSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                ),
              ),
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
                      subtitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderThresholdTile extends StatelessWidget {
  final bool enabled;
  final TextEditingController controller;
  final ReminderUnit unit;
  final ValueChanged<ReminderUnit> onUnitChanged;
  final ValueChanged<bool> onToggle;

  const _ReminderThresholdTile({
    required this.enabled,
    required this.controller,
    required this.unit,
    required this.onUnitChanged,
    required this.onToggle,
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
      child: Column(
        children: [
          Row(
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
                child: Text(
                  'Remind me if I have not done this',
                  style: AppTextStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'After',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<ReminderUnit>(
                    initialValue: unit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                    ),
                    items: [
                      for (final option in ReminderUnit.values)
                        DropdownMenuItem(
                          value: option,
                          child: Text(option.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        onUnitChanged(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
