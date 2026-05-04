import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/auth/biometric_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/howlong_button.dart';

class LockScreen extends ConsumerStatefulWidget {
  final VoidCallback onAuthenticated;

  const LockScreen({super.key, required this.onAuthenticated});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen>
    with WidgetsBindingObserver {
  bool _isAuthenticating = false;
  bool _authFailed = false;
  bool _biometricAvailable = true;
  bool _autoAuthStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(const Duration(milliseconds: 300), _checkAndAuthenticate);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isAuthenticating) {
      _resetAndReauthenticate();
    }
  }

  /// Resets stale auth state and re-triggers the biometric prompt.
  ///
  /// This handles two cases:
  /// 1. App resumed after the OS cancelled a mid-flight biometric dialog.
  /// 2. The lock screen is shown again after the 30-second re-lock timeout.
  void _resetAndReauthenticate() {
    // Cancel any platform-side biometric prompt that may be lingering.
    // `stopAuthentication()` is safe to call even if no auth is in progress.
    ref.read(biometricServiceProvider).cancelAuthentication();

    if (mounted) {
      setState(() {
        _isAuthenticating = false;
        _authFailed = false;
        _autoAuthStarted = false;
      });
      Future.delayed(
        const Duration(milliseconds: 300),
        _checkAndAuthenticate,
      );
    }
  }

  Future<void> _checkAndAuthenticate() async {
    if (_autoAuthStarted || _isAuthenticating) {
      return;
    }
    _autoAuthStarted = true;

    final biometricService = ref.read(biometricServiceProvider);
    final isAvailable = await biometricService.isBiometricAvailable();

    if (mounted) {
      if (isAvailable) {
        _triggerAuth();
      } else {
        setState(() {
          _biometricAvailable = false;
        });
      }
    }
  }

  Future<void> _triggerAuth() async {
    if (_isAuthenticating) {
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _authFailed = false;
    });

    final biometricService = ref.read(biometricServiceProvider);
    final success = await biometricService.authenticate();

    if (mounted) {
      if (success) {
        widget.onAuthenticated();
      } else {
        setState(() {
          _authFailed = true;
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGlow,
                    blurRadius: 24,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.timer_rounded,
                    size: 52, color: AppColors.accent),
              ),
            ),
            const SizedBox(height: 24),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'How',
                    style: AppTextStyles.displayLarge
                        .copyWith(fontWeight: FontWeight.w300),
                  ),
                  TextSpan(
                    text: 'Long',
                    style: AppTextStyles.displayLarge
                        .copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your private life tracker',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 64),
            if (_isAuthenticating)
              const CircularProgressIndicator(color: AppColors.primary)
            else if (!_biometricAvailable)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    const Icon(Icons.no_encryption_outlined,
                        size: 48, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'Biometric authentication is not available on this device.\nPlease enable fingerprint or Face ID in your device settings.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else
              const Icon(Icons.fingerprint, size: 72, color: AppColors.primary)
                  .animate(onPlay: (controller) => controller.repeat())
                  .scaleXY(
                      begin: 0.95,
                      end: 1.05,
                      duration: 1200.ms,
                      curve: Curves.easeInOut)
                  .then()
                  .scaleXY(begin: 1.05, end: 0.95, duration: 1200.ms),
            const SizedBox(height: 24),
            if (_authFailed)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text(
                      'Authentication failed',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.warning),
                    ),
                  ],
                ),
              ).animate().shake(),
            const SizedBox(height: 32),
            if (_biometricAvailable)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: HowLongButton(
                  label: _isAuthenticating
                      ? "Verifying..."
                      : "Unlock with Biometrics",
                  icon: Icons.lock_open_rounded,
                  onTap: _isAuthenticating ? null : _triggerAuth,
                  isLoading: _isAuthenticating,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
