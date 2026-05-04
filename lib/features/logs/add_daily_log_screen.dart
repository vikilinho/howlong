import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/isar_models.dart';
import '../../core/storage/storage_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/primary_action_button.dart';

class AddDailyLogScreen extends ConsumerStatefulWidget {
  final DateTime? initialDay;

  const AddDailyLogScreen({
    super.key,
    this.initialDay,
  });

  @override
  ConsumerState<AddDailyLogScreen> createState() => _AddDailyLogScreenState();
}

class _AddDailyLogScreenState extends ConsumerState<AddDailyLogScreen> {
  static const int maxLength = 500;

  final TextEditingController _bodyController = TextEditingController();
  DateTime _day = DateTime.now();
  String _mood = 'Okay';
  String _energy = 'Medium';
  bool _loadedExisting = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDay ?? DateTime.now();
    _day = DateTime(initial.year, initial.month, initial.day);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingLog());
  }

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingLog() async {
    final repository = await ref.read(dailyLogsRepositoryProvider.future);
    final existing = await repository.findForDay(_day);
    if (!mounted) return;

    if (existing != null) {
      setState(() {
        _bodyController.text = existing.body;
        _mood = existing.mood;
        _energy = existing.energy;
        _loadedExisting = true;
      });
      return;
    }

    setState(() => _loadedExisting = true);
  }

  void _leaveScreen() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;

    setState(() {
      _day = DateTime(picked.year, picked.month, picked.day);
      _bodyController.clear();
      _mood = 'Okay';
      _energy = 'Medium';
      _loadedExisting = false;
    });
    await _loadExistingLog();
  }

  Future<void> _saveLog() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);
    final repository = await ref.read(dailyLogsRepositoryProvider.future);
    await repository.saveLog(
      day: _day,
      body: body,
      mood: _mood,
      energy: _energy,
    );

    if (mounted) {
      _leaveScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _bodyController.text.trim();
    final canSave = body.isNotEmpty && _loadedExisting;

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
                    'Daily Log',
                    style: AppTextStyles.displayLarge.copyWith(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Share your thoughts about your day, what happened, and how it felt.',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 17,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _FormSection(
                    title: 'Day',
                    child: InkWell(
                      onTap: _pickDay,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _dayLabel(_day),
                                style: AppTextStyles.headingSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const Icon(Icons.edit_calendar_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FormSection(
                    title: 'How did today go?',
                    child: TextField(
                      controller: _bodyController,
                      minLines: 5,
                      maxLines: 7,
                      maxLength: maxLength,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Short note',
                        hintText:
                            'Felt focused today. Logged water, but skipped reading.',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FormSection(
                    title: 'Mood',
                    child: _ChoiceChips(
                      value: _mood,
                      tone: _ChipTone.mood,
                      options: const ['Good', 'Okay', 'Low'],
                      icons: const [
                        Icons.sentiment_satisfied_alt_rounded,
                        Icons.sentiment_neutral_rounded,
                        Icons.sentiment_dissatisfied_rounded,
                      ],
                      onChanged: (value) => setState(() => _mood = value),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FormSection(
                    title: 'Energy',
                    child: _ChoiceChips(
                      value: _energy,
                      tone: _ChipTone.energy,
                      options: const ['High', 'Medium', 'Low'],
                      icons: const [
                        Icons.bolt_rounded,
                        Icons.battery_4_bar_rounded,
                        Icons.battery_1_bar_rounded,
                      ],
                      onChanged: (value) => setState(() => _energy = value),
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
            onPressed: canSave && !_isSaving ? _saveLog : null,
            icon: Icons.edit_note_rounded,
            label: _isSaving ? 'Saving...' : 'Save Daily Log',
            isLoading: _isSaving,
          ),
        ),
      ),
    );
  }
}

class _ChoiceChips extends StatelessWidget {
  final String value;
  final _ChipTone tone;
  final List<String> options;
  final List<IconData> icons;
  final ValueChanged<String> onChanged;

  const _ChoiceChips({
    required this.value,
    required this.tone,
    required this.options,
    required this.icons,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var index = 0; index < options.length; index++) ...[
          _LogChoiceChip(
            label: options[index],
            icon: icons[index],
            selected: value == options[index],
            colors: _chipColors(tone, options[index]),
            onSelected: () => onChanged(options[index]),
          ),
        ],
      ],
    );
  }
}

enum _ChipTone { mood, energy }

class _LogChipColors {
  final Color foreground;
  final Color background;
  final Color selectedForeground;
  final Color selectedBackground;
  final Color border;

  const _LogChipColors({
    required this.foreground,
    required this.background,
    required this.selectedForeground,
    required this.selectedBackground,
    required this.border,
  });
}

class _LogChoiceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final _LogChipColors colors;
  final VoidCallback onSelected;

  const _LogChoiceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.colors,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? colors.selectedForeground : colors.foreground;
    return ChoiceChip(
      selected: selected,
      avatar: Icon(icon, size: 18, color: foreground),
      label: Text(label),
      onSelected: (_) => onSelected(),
      selectedColor: colors.selectedBackground,
      backgroundColor: colors.background,
      labelStyle: AppTextStyles.labelLarge.copyWith(
        color: foreground,
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide(
        color: selected ? colors.selectedBackground : colors.border,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    );
  }
}

_LogChipColors _chipColors(_ChipTone tone, String value) {
  if (tone == _ChipTone.energy) {
    return switch (value) {
      'High' => const _LogChipColors(
          foreground: Color(0xFF7A3D00),
          background: Color(0xFFFFF1D6),
          selectedForeground: Colors.white,
          selectedBackground: Color(0xFFF59E0B),
          border: Color(0xFFF8D9A3),
        ),
      'Low' => const _LogChipColors(
          foreground: Color(0xFF334155),
          background: Color(0xFFEFF4FB),
          selectedForeground: Colors.white,
          selectedBackground: Color(0xFF64748B),
          border: Color(0xFFD6E0ED),
        ),
      _ => const _LogChipColors(
          foreground: Color(0xFF075985),
          background: Color(0xFFE0F2FE),
          selectedForeground: Colors.white,
          selectedBackground: Color(0xFF0284C7),
          border: Color(0xFFBAE6FD),
        ),
    };
  }

  return switch (value) {
    'Good' => const _LogChipColors(
        foreground: Color(0xFF166534),
        background: Color(0xFFDCFCE7),
        selectedForeground: Colors.white,
        selectedBackground: Color(0xFF16A34A),
        border: Color(0xFFBBF7D0),
      ),
    'Low' => const _LogChipColors(
        foreground: Color(0xFF991B1B),
        background: Color(0xFFFEE2E2),
        selectedForeground: Colors.white,
        selectedBackground: Color(0xFFDC2626),
        border: Color(0xFFFECACA),
      ),
    _ => const _LogChipColors(
        foreground: Color(0xFF5B4B00),
        background: Color(0xFFFEF9C3),
        selectedForeground: Color(0xFF2D2400),
        selectedBackground: Color(0xFFFDE047),
        border: Color(0xFFFEF08A),
      ),
  };
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
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
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
        ],
      ),
    );
  }
}

String _dayLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  if (target == today) return 'Today';
  if (target == today.subtract(const Duration(days: 1))) return 'Yesterday';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String dailyLogDayLabel(DailyLog log) => _dayLabel(log.day);
