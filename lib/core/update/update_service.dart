import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppUpdateAvailability {
  unavailable,
  available,
}

class AppUpdateCheckResult {
  final AppUpdateAvailability availability;
  final bool canUseImmediateFlow;
  final String? currentVersionLabel;
  final DateTime checkedAt;

  const AppUpdateCheckResult({
    required this.availability,
    required this.canUseImmediateFlow,
    required this.checkedAt,
    this.currentVersionLabel,
  });

  bool get hasUpdate => availability == AppUpdateAvailability.available;
}

class UpdateService {
  UpdateService(this._prefs);

  static const _lastCheckedKey = 'app_update_last_checked_at';
  static const _checkCooldown = Duration(hours: 12);

  final SharedPreferences _prefs;

  Future<AppUpdateCheckResult?> checkForUpdateIfDue() async {
    final lastCheckedRaw = _prefs.getString(_lastCheckedKey);
    if (lastCheckedRaw != null) {
      final lastChecked = DateTime.tryParse(lastCheckedRaw);
      if (lastChecked != null &&
          DateTime.now().difference(lastChecked) < _checkCooldown) {
        return null;
      }
    }

    final result = await checkForUpdate();
    await _prefs.setString(_lastCheckedKey, result.checkedAt.toIso8601String());
    return result;
  }

  Future<AppUpdateCheckResult> checkForUpdate() async {
    final checkedAt = DateTime.now();

    if (kIsWeb || !Platform.isAndroid) {
      return AppUpdateCheckResult(
        availability: AppUpdateAvailability.unavailable,
        canUseImmediateFlow: false,
        checkedAt: checkedAt,
      );
    }

    try {
      final info = await InAppUpdate.checkForUpdate();
      final isAvailable = info.updateAvailability ==
          UpdateAvailability.updateAvailable;
      final canUseImmediate =
          isAvailable && info.immediateUpdateAllowed == true;
      final canUseFlexible =
          isAvailable && info.flexibleUpdateAllowed == true;

      return AppUpdateCheckResult(
        availability: isAvailable
            ? AppUpdateAvailability.available
            : AppUpdateAvailability.unavailable,
        canUseImmediateFlow: canUseImmediate || canUseFlexible,
        currentVersionLabel: info.availableVersionCode?.toString(),
        checkedAt: checkedAt,
      );
    } catch (error, stackTrace) {
      debugPrint('Update check failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return AppUpdateCheckResult(
        availability: AppUpdateAvailability.unavailable,
        canUseImmediateFlow: false,
        checkedAt: checkedAt,
      );
    }
  }

  Future<bool> performUpdate() async {
    if (kIsWeb || !Platform.isAndroid) return false;

    try {
      await InAppUpdate.performImmediateUpdate();
      return true;
    } catch (error, stackTrace) {
      debugPrint('Immediate update failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }
}
