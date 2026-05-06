import 'package:flutter/material.dart';

import '../../core/feedback/app_haptics.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final effectiveOnPressed = onPressed;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: isDisabled && !isLoading ? 0.48 : 1,
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        shadowColor: AppColors.primary.withValues(alpha: 0.22),
        elevation: isDisabled ? 0 : 8,
        child: InkWell(
          onTap: isLoading || effectiveOnPressed == null
              ? null
              : () {
                  AppHaptics.confirm();
                  effectiveOnPressed();
                },
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.white.withValues(alpha: 0.12),
          highlightColor: Colors.white.withValues(alpha: 0.06),
          child: Container(
            width: double.infinity,
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white.withValues(alpha: 0.78),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
