import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/features/auth/presentation/screens/login_screen.dart';
import 'package:worksense_app/features/camera_monitor/presentation/screens/entrance_kiosk_screen.dart';
import 'package:worksense_app/features/camera_monitor/presentation/screens/kiosk_screen.dart';
import 'package:worksense_app/features/camera_monitor/presentation/screens/kiosk_waiting_screen.dart';
import 'package:worksense_app/features/dashboard/presentation/screens/activity_history_screen.dart';
import 'package:worksense_app/features/dashboard/presentation/screens/admin_analytics_screen.dart';
import 'package:worksense_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:worksense_app/features/dashboard/presentation/screens/employee_detail_analytics_screen.dart';
import 'package:worksense_app/features/dashboard/presentation/screens/my_activity_screen.dart';
import 'package:worksense_app/features/dashboard/presentation/screens/my_hours_screen.dart';
import 'package:worksense_app/features/employees/presentation/screens/employee_form_screen.dart';
import 'package:worksense_app/features/employees/presentation/screens/employees_list_screen.dart';
import 'package:worksense_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:worksense_app/features/workstations/presentation/screens/workstation_form_screen.dart';
import 'package:worksense_app/features/workstations/presentation/screens/workstations_list_screen.dart';
import 'package:worksense_app/features/shifts/presentation/screens/shifts_list_screen.dart';
import 'package:worksense_app/features/shifts/presentation/screens/shift_form_screen.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

// ── Route constants ────────────────────────────────────────────────────────────

abstract final class AppRoutes {
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const kiosk = '/kiosk/:workstationId';
  static const history = '/history';
  static const employees = '/employees';
  static const employeeNew = '/employees/new';
  static const settings = '/settings';
  static const workstations = '/workstations';
  static const workstationNew = '/workstations/new';
  static const kioskWaiting = '/kiosk_waiting';
  static const entrance = '/entrance';
  static const myActivity = '/my-activity';
  static const myHours = '/my-hours';
  static const analytics = '/analytics';
  static const analyticsDetail = '/analytics/:employeeId';
  static const shifts = '/shifts';
  static const shiftNew = '/shift_form';
}

// ── Router provider ───────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier(ref);
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final currentUserState = ref.read(currentUserProvider);

      if (currentUserState.isLoading) return null;

      final currentUser = currentUserState.valueOrNull;
      final isAuthenticated = currentUser?.user != null;
      final loc = state.matchedLocation;
      final isOnLoginPage = loc == AppRoutes.login;

      // Not logged in → login
      if (!isAuthenticated && !isOnLoginPage) return AppRoutes.login;

      // Already logged in → leave login
      if (isAuthenticated && isOnLoginPage) return AppRoutes.dashboard;

      // Role-based guards
      if (isAuthenticated && currentUser != null) {
        final role = currentUser.role;

        switch (role) {
          case AppRole.cameraMonitor:
            // Camera monitors can only access kiosk routes
            final allowed = loc.startsWith('/kiosk') || loc == AppRoutes.entrance;
            if (!allowed && loc != AppRoutes.login) {
              return AppRoutes.kioskWaiting;
            }
            break;

          case AppRole.employee:
            const allowedEmployeeRoutes = [
              AppRoutes.myActivity,
              AppRoutes.myHours,
              AppRoutes.settings,
            ];
            if (!allowedEmployeeRoutes.contains(loc) && loc != AppRoutes.login) {
              return AppRoutes.myActivity;
            }
            break;

          case AppRole.admin:
          case AppRole.superAdmin:
            // No restrictions — admins can access all routes
            break;
        }
      }

      return null;
    },
    routes: [
      // ── Auth ────────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginScreen(),
        ),
      ),

      // ── Admin Dashboard ──────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: DashboardScreen(),
        ),
      ),

      // ── Employee screens ─────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.myActivity,
        name: 'my-activity',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: MyActivityScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.myHours,
        name: 'my-hours',
        pageBuilder: (context, state) => const MaterialPage(
          child: MyHoursScreen(),
        ),
      ),

      // ── Kiosk ────────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.kioskWaiting,
        name: 'kiosk-waiting',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: KioskWaitingScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.entrance,
        name: 'entrance',
        pageBuilder: (context, state) => const MaterialPage(
          child: EntranceKioskScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.kiosk,
        name: 'kiosk',
        pageBuilder: (context, state) {
          final workstationId = state.pathParameters['workstationId'];
          return MaterialPage(
            child: KioskScreen(workstationId: workstationId),
          );
        },
      ),

      // ── Analytics ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.analytics,
        name: 'analytics',
        pageBuilder: (context, state) => const MaterialPage(
          child: AdminAnalyticsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.analyticsDetail,
        name: 'analytics-detail',
        pageBuilder: (context, state) {
          final employeeId = state.pathParameters['employeeId'] ?? '';
          return MaterialPage(
            child: EmployeeDetailAnalyticsScreen(employeeId: employeeId),
          );
        },
      ),

      // ── Employees ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.employees,
        name: 'employees',
        pageBuilder: (context, state) => const MaterialPage(
          child: EmployeesListScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.employeeNew,
        name: 'employee-new',
        pageBuilder: (context, state) => const MaterialPage(
          child: EmployeeFormScreen(),
        ),
      ),

      // ── Shifts ───────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.shifts,
        name: 'shifts',
        pageBuilder: (context, state) => const MaterialPage(
          child: ShiftsListScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.shiftNew,
        name: 'shift-new',
        pageBuilder: (context, state) => const MaterialPage(
          child: ShiftFormScreen(),
        ),
      ),

      // ── Workstations ─────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.workstations,
        name: 'workstations',
        pageBuilder: (context, state) => const MaterialPage(
          child: WorkstationsListScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.workstationNew,
        name: 'workstation-new',
        pageBuilder: (context, state) => const MaterialPage(
          child: WorkstationFormScreen(),
        ),
      ),

      // ── History ──────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.history,
        name: 'history',
        pageBuilder: (context, state) => const MaterialPage(
          child: ActivityHistoryScreen(),
        ),
      ),

      // ── Settings ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => const MaterialPage(
          child: SettingsScreen(),
        ),
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      child: _RouteErrorScreen(
        error: state.error?.message ?? 'Ruta no encontrada',
      ),
    ),
  );
});

// ── Auth change notifier ───────────────────────────────────────────────────────

class _AuthNotifier extends ChangeNotifier {
  final Ref _ref;

  _AuthNotifier(this._ref) {
    _ref.listen<AsyncValue<CurrentUser>>(currentUserProvider, (_, __) {
      notifyListeners();
    });
  }
}

// ── Error screen ──────────────────────────────────────────────────────────────

class _RouteErrorScreen extends StatelessWidget {
  final String error;

  const _RouteErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página no encontrada')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(error),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Ir al dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
