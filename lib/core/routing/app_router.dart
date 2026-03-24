import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/features/auth/presentation/screens/login_screen.dart';
import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:worksense_app/features/camera_monitor/presentation/screens/kiosk_screen.dart';
import 'package:worksense_app/features/dashboard/presentation/screens/activity_history_screen.dart';
import 'package:worksense_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:worksense_app/features/employees/presentation/screens/employee_form_screen.dart';
import 'package:worksense_app/features/employees/presentation/screens/employees_list_screen.dart';
import 'package:worksense_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:worksense_app/features/workstations/presentation/screens/workstation_form_screen.dart';
import 'package:worksense_app/features/workstations/presentation/screens/workstations_list_screen.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';


// Route name constants
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
  static const myActivity = '/my-activity';
  static const myHours = '/my-hours';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier(ref);
  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final currentUserState = ref.read(currentUserProvider);
      
      if (currentUserState.isLoading) return null; // Wait for resolution

      final currentUser = currentUserState.valueOrNull;
      final isAuthenticated = currentUser?.user != null;
      final isOnLoginPage = state.matchedLocation == AppRoutes.login;

      if (!isAuthenticated && !isOnLoginPage) {
        return AppRoutes.login;
      }

      if (isAuthenticated && isOnLoginPage) {
        return AppRoutes.dashboard;
      }

      if (isAuthenticated && currentUser != null) {
        final role = currentUser.role;
        final loc = state.matchedLocation;

        switch (role) {
          case AppRole.cameraMonitor:
            if (!loc.startsWith('/kiosk') && loc != AppRoutes.login) {
              return AppRoutes.kioskWaiting;
            }
            break;
          case AppRole.employee:
            final allowedEmployeeRoutes = [AppRoutes.myActivity, AppRoutes.myHours, AppRoutes.settings];
            if (!allowedEmployeeRoutes.contains(loc) && loc != AppRoutes.login) {
              return AppRoutes.myActivity;
            }
            break;
          case AppRole.admin:
            if (loc.startsWith('/kiosk')) {
              return AppRoutes.dashboard;
            }
            break;
          case AppRole.superAdmin:
            break;
        }
      }

      return null;
    },
    routes: [
      // Auth
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginScreen(),
        ),
      ),

      // Dashboard
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: DashboardScreen(),
        ),
      ),

      // Kiosk
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

      // Activity history
      GoRoute(
        path: AppRoutes.history,
        name: 'history',
        pageBuilder: (context, state) => const MaterialPage(
          child: ActivityHistoryScreen(),
        ),
      ),

      // Employees list
      GoRoute(
        path: AppRoutes.employees,
        name: 'employees',
        pageBuilder: (context, state) => const MaterialPage(
          child: EmployeesListScreen(),
        ),
      ),

      // Employee form (new)
      GoRoute(
        path: AppRoutes.employeeNew,
        name: 'employee-new',
        pageBuilder: (context, state) => const MaterialPage(
          child: EmployeeFormScreen(),
        ),
      ),

      // Workstations
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

      GoRoute(
        path: AppRoutes.kioskWaiting,
        name: 'kiosk-waiting',
        pageBuilder: (context, state) => NoTransitionPage(
          child: Consumer(
            builder: (context, ref, child) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Configuración'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () => ref.read(loginNotifierProvider.notifier).signOut(),
                    ),
                  ],
                ),
                body: const Center(child: Text('Dispositivo no configurado')),
              );
            },
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.myActivity,
        name: 'my-activity',
        pageBuilder: (context, state) => NoTransitionPage(
          child: Consumer(
            builder: (context, ref, child) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Mi Actividad'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () => ref.read(loginNotifierProvider.notifier).signOut(),
                    ),
                  ],
                ),
                body: const Center(child: Text('Panel de empleado — Próximamente')),
              );
            },
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.myHours,
        name: 'my-hours',
        pageBuilder: (context, state) => NoTransitionPage(
          child: Consumer(
            builder: (context, ref, child) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Mis Horas'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () => ref.read(loginNotifierProvider.notifier).signOut(),
                    ),
                  ],
                ),
                body: const Center(child: Text('Mis horas — Próximamente')),
              );
            },
          ),
        ),
      ),


      // Settings
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => const MaterialPage(
          child: SettingsScreen(),
        ),
      ),
    ],
    errorPageBuilder: (context, state) => MaterialPage(
      child: _RouteErrorScreen(error: state.error?.message ?? 'Ruta no encontrada'),
    ),
  );
});

/// A [ChangeNotifier] that triggers GoRouter refresh on auth state changes.
class _AuthNotifier extends ChangeNotifier {
  final Ref _ref;

  _AuthNotifier(this._ref) {
    _ref.listen<AsyncValue<CurrentUser>>(currentUserProvider, (_, __) {
      notifyListeners();
    });
  }
}

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
