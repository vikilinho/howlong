import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class HowLongButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double height;
  final EdgeInsets? padding;

  const HowLongButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.foregroundColor,
    this.width = double.infinity,
    this.height = 52,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onTap == null;
    final Color effectiveBgColor = backgroundColor ?? AppColors.buttonText;
    final Color effectiveFgColor = foregroundColor ?? Colors.white;

    Widget buttonContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              color: effectiveFgColor,
              strokeWidth: 2,
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 20, color: effectiveFgColor),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: AppTextStyles.buttonLabel.copyWith(color: effectiveFgColor),
          ),
        ]
      ],
    );

    Widget material = Material(
      color: isOutlined ? Colors.transparent : effectiveBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOutlined
            ? const BorderSide(color: AppColors.accent, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.accent.withValues(alpha: 0.20),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          alignment: Alignment.center,
          child: buttonContent,
        ),
      ),
    );

    return Opacity(
        opacity: isDisabled && !isLoading ? 0.4 : 1.0,
        child: material.animate(
            target: isLoading ? 0 : 1) // Optionally configure animation here
        );
  }
}
