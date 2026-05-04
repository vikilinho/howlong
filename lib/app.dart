import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/storage/storage_providers.dart';
import 'core/theme/app_theme.dart';
import 'core/update/update_service.dart';
import 'features/events/action_detail_screen.dart';
import 'features/events/add_event_screen.dart';
import 'features/habits/add_habit_screen.dart';
import 'features/habits/habit_detail_screen.dart';
import 'features/home/home_screen.dart';
import 'features/lock/lock_screen.dart';
import 'features/logs/add_daily_log_screen.dart';

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

final updateServiceProvider = FutureProvider<UpdateService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return UpdateService(prefs);
});

class HowLongApp extends ConsumerStatefulWidget {
  const HowLongApp({super.key});

  @override
  ConsumerState<HowLongApp> createState() => _HowLongAppState();
}

class _HowLongAppState extends ConsumerState<HowLongApp> {
  bool _isUnlocked = false;
  DateTime? _lastActiveTime;
  int _lockKey =
      0; // Incremented to force a fresh LockScreen widget on re-lock.
  late final AppLifecycleListener _lifecycleListener;

  late final GoRouter _router = GoRouter(
    initialLocation: kDebugMode ? '/home' : '/lock',
    routes: [
      GoRoute(
          path: '/lock',
          builder: (_, __) => LockScreen(
                key: ValueKey('lock_$_lockKey'),
                onAuthenticated: _onAuthenticated,
              )),
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
          builder: (ctx, state) => _EditActionRoute(
              actionId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1)),
      GoRoute(path: '/habits/add', builder: (_, __) => const AddHabitScreen()),
      GoRoute(
          path: '/habits/:id',
          builder: (ctx, state) => HabitDetailScreen(
              habitId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1)),
      GoRoute(
          path: '/habits/:id/edit',
          builder: (ctx, state) => _EditHabitRoute(
              habitId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1)),
      GoRoute(
        path: '/logs/add',
        builder: (_, __) => const AddDailyLogScreen(),
      ),
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
            _relock();
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

  void _relock() {
    final biometricVal = ref.read(biometricEnabledProvider).valueOrNull ?? true;
    if (!biometricVal) return;

    final currentPath = _router.routeInformationProvider.value.uri.path;
    final isLockLocation = currentPath == '/lock';

    setState(() {
      _isUnlocked = false;
      _lockKey++; // Force GoRouter to build a fresh LockScreen instance.
    });

    if (!isLockLocation) {
      _router.go('/lock');
    }
  }

  void _onAuthenticated() {
    if (_isUnlocked) {
      return;
    }

    setState(() {
      _isUnlocked = true;
      _lastActiveTime = null; // Clear so re-lock timer starts fresh.
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

class _EditActionRoute extends ConsumerWidget {
  final int actionId;

  const _EditActionRoute({required this.actionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);
    return events.when(
      data: (items) {
        final event = items.where((item) => item.id == actionId).firstOrNull;
        if (event == null) {
          return const Scaffold(body: Center(child: Text('Action not found')));
        }
        return AddEventScreen(event: event);
      },
      error: (error, _) =>
          Scaffold(body: Center(child: Text(error.toString()))),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _EditHabitRoute extends ConsumerWidget {
  final int habitId;

  const _EditHabitRoute({required this.habitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitsProvider);
    return habits.when(
      data: (items) {
        final habit = items.where((item) => item.id == habitId).firstOrNull;
        if (habit == null) {
          return const Scaffold(body: Center(child: Text('Habit not found')));
        }
        return AddHabitScreen(habit: habit);
      },
      error: (error, _) =>
          Scaffold(body: Center(child: Text(error.toString()))),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
