import 'package:flutter/services.dart';

class AppHaptics {
  const AppHaptics._();

  static Future<void> tap() {
    return HapticFeedback.selectionClick();
  }

  static Future<void> confirm() {
    return HapticFeedback.lightImpact();
  }

  static Future<void> destructive() {
    return HapticFeedback.mediumImpact();
  }
}
