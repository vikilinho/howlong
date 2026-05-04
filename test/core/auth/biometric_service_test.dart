import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';

import 'package:howlong/core/auth/biometric_service.dart';

// ---------------------------------------------------------------------------
// Fake platform implementation used to drive LocalAuthentication from tests.
// ---------------------------------------------------------------------------
class FakeLocalAuthPlatform extends LocalAuthPlatform {
  bool supportsBiometrics = true;
  bool deviceSupported = true;
  List<BiometricType> enrolledBiometrics = [BiometricType.fingerprint];

  bool authenticateResult = true;
  bool shouldThrowAuthInProgress = false;
  bool shouldThrowPermanentlyLocked = false;
  bool shouldThrowGeneric = false;

  int authenticateCallCount = 0;
  int stopAuthenticationCallCount = 0;
  bool stopAuthenticationThrows = false;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    required Iterable<AuthMessages> authMessages,
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async {
    authenticateCallCount++;

    if (shouldThrowAuthInProgress) {
      // Simulate the platform throwing when a prompt is already showing.
      throw PlatformException(
        code: 'auth_in_progress',
        message: 'Authentication already in progress',
      );
    }

    if (shouldThrowPermanentlyLocked) {
      throw PlatformException(
        code: 'PermanentlyLockedOut',
        message: 'Too many attempts',
      );
    }

    if (shouldThrowGeneric) {
      throw Exception('Something unexpected');
    }

    return authenticateResult;
  }

  @override
  Future<bool> deviceSupportsBiometrics() async => supportsBiometrics;

  @override
  Future<bool> isDeviceSupported() async => deviceSupported;

  @override
  Future<List<BiometricType>> getEnrolledBiometrics() async =>
      enrolledBiometrics;

  @override
  Future<bool> stopAuthentication() async {
    stopAuthenticationCallCount++;
    if (stopAuthenticationThrows) {
      throw PlatformException(
        code: 'not_supported',
        message: 'Not supported on this platform',
      );
    }
    return true;
  }
}

void main() {
  late FakeLocalAuthPlatform fakePlatform;
  late BiometricService service;

  setUp(() {
    fakePlatform = FakeLocalAuthPlatform();
    // Register the fake as the active platform instance.
    LocalAuthPlatform.instance = fakePlatform;
    service = BiometricService();
  });

  // -------------------------------------------------------------------------
  // isBiometricAvailable
  // -------------------------------------------------------------------------
  group('isBiometricAvailable', () {
    test('returns true when biometrics are supported', () async {
      fakePlatform.supportsBiometrics = true;
      fakePlatform.deviceSupported = true;

      expect(await service.isBiometricAvailable(), isTrue);
    });

    test('returns true when only device credentials are supported', () async {
      fakePlatform.supportsBiometrics = false;
      fakePlatform.deviceSupported = true;

      expect(await service.isBiometricAvailable(), isTrue);
    });

    test('returns false when device is not supported', () async {
      fakePlatform.supportsBiometrics = false;
      fakePlatform.deviceSupported = false;

      expect(await service.isBiometricAvailable(), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // authenticate
  // -------------------------------------------------------------------------
  group('authenticate', () {
    test('returns true on successful authentication', () async {
      fakePlatform.authenticateResult = true;

      expect(await service.authenticate(), isTrue);
      expect(fakePlatform.authenticateCallCount, 1);
    });

    test('returns false when user cancels', () async {
      fakePlatform.authenticateResult = false;

      expect(await service.authenticate(), isFalse);
    });

    test('returns false on PlatformException (e.g. permanently locked)',
        () async {
      fakePlatform.shouldThrowPermanentlyLocked = true;

      expect(await service.authenticate(), isFalse);
    });

    test('returns false on generic exception', () async {
      fakePlatform.shouldThrowGeneric = true;

      expect(await service.authenticate(), isFalse);
    });

    test('handles auth_in_progress by calling stopAuthentication', () async {
      fakePlatform.shouldThrowAuthInProgress = true;

      final result = await service.authenticate();

      // Should return false (does not retry automatically).
      expect(result, isFalse);
      // Should have called stopAuthentication to clean up.
      expect(fakePlatform.stopAuthenticationCallCount, 1);
    });
  });

  // -------------------------------------------------------------------------
  // cancelAuthentication
  // -------------------------------------------------------------------------
  group('cancelAuthentication', () {
    test('calls stopAuthentication on the platform', () async {
      await service.cancelAuthentication();

      expect(fakePlatform.stopAuthenticationCallCount, 1);
    });

    test('does not throw when platform does not support stop', () async {
      fakePlatform.stopAuthenticationThrows = true;

      // Should silently swallow the exception.
      await expectLater(service.cancelAuthentication(), completes);
    });

    test('can be called multiple times safely', () async {
      await service.cancelAuthentication();
      await service.cancelAuthentication();
      await service.cancelAuthentication();

      expect(fakePlatform.stopAuthenticationCallCount, 3);
    });
  });

  // -------------------------------------------------------------------------
  // hasFaceId
  // -------------------------------------------------------------------------
  group('hasFaceId', () {
    test('returns true when face biometric is enrolled', () async {
      fakePlatform.enrolledBiometrics = [BiometricType.face];

      // Must call isBiometricAvailable first to populate the internal list.
      await service.isBiometricAvailable();

      expect(service.hasFaceId, isTrue);
    });

    test('returns false when only fingerprint is enrolled', () async {
      fakePlatform.enrolledBiometrics = [BiometricType.fingerprint];

      await service.isBiometricAvailable();

      expect(service.hasFaceId, isFalse);
    });

    test('returns false before isBiometricAvailable is called', () {
      // _availableBiometrics defaults to empty.
      expect(service.hasFaceId, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Resume / re-lock scenario integration
  // -------------------------------------------------------------------------
  group('resume re-lock scenario', () {
    test(
        'cancel then re-authenticate works after simulated app resume',
        () async {
      // Step 1: First authentication succeeds.
      fakePlatform.authenticateResult = true;
      expect(await service.authenticate(), isTrue);
      expect(fakePlatform.authenticateCallCount, 1);

      // Step 2: Simulate app going to background — platform cancels the
      // biometric dialog. On resume, the lock screen calls cancel first.
      await service.cancelAuthentication();
      expect(fakePlatform.stopAuthenticationCallCount, 1);

      // Step 3: Re-authenticate after cancel (fresh prompt).
      fakePlatform.authenticateResult = true;
      final result = await service.authenticate();
      expect(result, isTrue);
      expect(fakePlatform.authenticateCallCount, 2);
    });

    test(
        'auth_in_progress followed by successful retry works',
        () async {
      // First call throws auth_in_progress (stale dialog).
      fakePlatform.shouldThrowAuthInProgress = true;
      final firstResult = await service.authenticate();
      expect(firstResult, isFalse);
      expect(fakePlatform.stopAuthenticationCallCount, 1);

      // After the lock screen resets state and retries, it works.
      fakePlatform.shouldThrowAuthInProgress = false;
      fakePlatform.authenticateResult = true;
      final secondResult = await service.authenticate();
      expect(secondResult, isTrue);
    });
  });
}
