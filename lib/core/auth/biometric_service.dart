import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BiometricService {
  final LocalAuthentication _localAuth;
  List<BiometricType> _availableBiometrics = [];

  BiometricService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (canAuthenticate) {
        _availableBiometrics = await getAvailableBiometrics();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Unlock HowLong to access your private tracking data',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      // If a previous auth session is still active, cancel it and retry once.
      if (e.code == 'auth_in_progress') {
        await cancelAuthentication();
        return false;
      }
      // Handles notEnrolled, lockedOut, permanentlyLockedOut, etc.
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Cancels any in-flight platform biometric prompt.
  ///
  /// Safe to call even when no authentication is in progress.
  Future<void> cancelAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (_) {
      // stopAuthentication() may throw on platforms that don't support it.
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return <BiometricType>[];
    }
  }

  bool get hasFaceId {
    return _availableBiometrics.contains(BiometricType.face);
  }
}

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});
