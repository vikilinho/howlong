import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/events/action_detail_screen.dart';
import 'features/events/add_event_screen.dart';
import 'features/habits/add_habit_screen.dart';
import 'features/habits/habit_detail_screen.dart';
import 'features/home/home_screen.dart';
import 'features/lock/lock_screen.dart';

final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

final biometricEnabledProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return prefs.getBool('biometric_enabled') ?? true;
});

final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return prefs.getBool('onboarding_complete') ?? false;
});

class HowLongApp extends ConsumerStatefulWidget {
  const HowLongApp({super.key});

  @override
  ConsumerState<HowLongApp> createState() => _HowLongAppState();
}

class _HowLongAppState extends ConsumerState<HowLongApp> {
  bool _isUnlocked = false;
  DateTime? _lastActiveTime;
  late final AppLifecycleListener _lifecycleListener;

  late final GoRouter _router = GoRouter(
    initialLocation: kDebugMode ? '/home' : '/lock',
    routes: [
      GoRoute(
          path: '/lock',
          builder: (_, __) => LockScreen(onAuthenticated: _onAuthenticated)),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(
          path: '/settings',
          builder: (_, __) => const Scaffold(
              body: Center(child: Text('Settings - Phase 2 stub')))),
      GoRoute(path: '/events/add', builder: (_, __) => const AddEventScreen()),
      GoRoute(
          path: '/events/:id',
          builder: (ctx, state) => ActionDetailScreen(
              actionId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1)),
      GoRoute(
          path: '/events/:id/edit',
          builder: (ctx, state) => const Scaffold(
              body: Center(child: Text('Edit Action - Phase 2')))),
      GoRoute(path: '/habits/add', builder: (_, __) => const AddHabitScreen()),
      GoRoute(
          path: '/habits/:id',
          builder: (ctx, state) => HabitDetailScreen(
              habitId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1)),
      GoRoute(
          path: '/habits/:id/edit',
          builder: (ctx, state) => const Scaffold(
              body: Center(child: Text('Edit Habit - Phase 3')))),
    ],
    redirect: (context, state) {
      if (kDebugMode) {
        return state.uri.toString() == '/lock' ? '/home' : null;
      }

      final biometricVal =
          ref.read(biometricEnabledProvider).valueOrNull ?? true;
      final isLockLocation = state.uri.toString() == '/lock';

      if (!biometricVal && isLockLocation) {
        return '/home';
      }

      if (biometricVal && !_isUnlocked && !isLockLocation) {
        return '/lock';
      }

      return null;
    },
  );

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onPause: () => _lastActiveTime = DateTime.now(),
      onResume: () {
        if (kDebugMode) {
          return;
        }

        if (_lastActiveTime != null) {
          final difference = DateTime.now().difference(_lastActiveTime!);
          if (difference.inSeconds > 30) {
            final biometricVal =
                ref.read(biometricEnabledProvider).valueOrNull ?? true;
            if (biometricVal) {
              setState(() {
                _isUnlocked = false;
              });
              _router.go('/lock');
            }
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _onAuthenticated() {
    setState(() {
      _isUnlocked = true;
    });
    _router.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'HowLong',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
    );
  }
}
