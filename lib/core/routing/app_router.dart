import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/features/alerts/presentation/screens/alert_log_screen.dart';
import 'package:worksense_app/features/announcements/presentation/screens/announcement_form_screen.dart';
import 'package:worksense_app/features/announcements/presentation/screens/announcements_screen.dart';
import 'package:worksense_app/features/auth/presentation/screens/login_screen.dart';
import 'package:worksense_app/features/reports/presentation/screens/reports_screen.dart';
import 'package:worksense_app/features/camera_monitor/presentation/screens/kiosk_screen.dart';
import 'package:worksense_app/features/camera_monitor/presentation/screens/entrance_kiosk_screen.dart';
import 'package:worksense_app/features/camera_monitor/presentation/screens/kiosk_waiting_screen.dart';
import 'package:worksense_app/features/dashboard/presentation/screens/activity_history_screen.dart';
import 'package:worksense_app/features/dashboard/presentation/screens/admin_analytics_screen.dart';
import 'package:worksense_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:worksense_app/features/dashboard/presentation/screens/employee_detail_analytics_screen.dart';
import 'package:worksense_app/features/dashboard/presentation/screens/my_activity_screen.dart';
import 'package:worksense_app/features/dashboard/presentation/screens/my_hours_screen.dart';
import 'package:worksense_app/features/employees/presentation/screens/employee_form_screen.dart';
import 'package:worksense_app/features/employees/presentation/screens/employees_list_screen.dart';
import 'package:worksense_app/features/dashboard/presentation/screens/shifts_list_screen.dart';
import 'package:worksense_app/features/dashboard/presentation/screens/shift_form_screen.dart';
import 'package:worksense_app/features/leaves/presentation/screens/leave_request_form_screen.dart';
import 'package:worksense_app/features/leaves/presentation/screens/leaves_list_screen.dart';
import 'package:worksense_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:worksense_app/features/tasks/presentation/screens/task_form_screen.dart';
import 'package:worksense_app/features/tasks/presentation/screens/tasks_list_screen.dart';
import 'package:worksense_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:worksense_app/features/workstations/presentation/screens/workstation_form_screen.dart';
import 'package:worksense_app/features/workstations/presentation/screens/workstations_list_screen.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/screens/home_employee_screen.dart';
import 'package:worksense_app/core/constants/constants.dart';
import 'package:worksense_app/core/navigation/scaffold_with_bottom_nav.dart';
import 'package:worksense_app/core/routing/route_error_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorDashboardKey = GlobalKey<NavigatorState>(debugLabel: 'shellDashboard');
final GlobalKey<NavigatorState> _shellNavigatorEmployeesKey = GlobalKey<NavigatorState>(debugLabel: 'shellEmployees');
final GlobalKey<NavigatorState> _shellNavigatorWorkstationsKey = GlobalKey<NavigatorState>(debugLabel: 'shellWorkstations');
final GlobalKey<NavigatorState> _shellNavigatorHistoryKey = GlobalKey<NavigatorState>(debugLabel: 'shellHistory');
final GlobalKey<NavigatorState> _shellNavigatorSettingsKey = GlobalKey<NavigatorState>(debugLabel: 'shellSettings');
final GlobalKey<NavigatorState> _shellNavigatorShiftsKey = GlobalKey<NavigatorState>(debugLabel: 'shellShifts');
final GlobalKey<NavigatorState> _shellNavigatorTasksKey = GlobalKey<NavigatorState>(debugLabel: 'shellTasks');
final GlobalKey<NavigatorState> _shellNavigatorLeavesKey = GlobalKey<NavigatorState>(debugLabel: 'shellLeaves');


final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier(ref);
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    navigatorKey: _rootNavigatorKey,
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

        // Si acaban de hacer login o están en la raíz, los mandamos a su home
        if (loc == AppRoutes.login || loc == '/') {
          if (role == AppRole.cameraMonitor) return AppRoutes.kioskWaiting;
          return AppRoutes.dashboard;
        }

        switch (role) {
          case AppRole.cameraMonitor:
            if (!loc.startsWith('/kiosk') && loc != AppRoutes.entrance && loc != AppRoutes.login) {
              return AppRoutes.kioskWaiting;
            }
            break;
          case AppRole.employee:
            final allowedEmployeeRoutes = [
              AppRoutes.dashboard,
              AppRoutes.history,
              AppRoutes.myActivity,
              AppRoutes.myHours,
              AppRoutes.settings,
              AppRoutes.tasks,
              AppRoutes.leaves,
              AppRoutes.leaveNew,
              AppRoutes.announcements,
              AppRoutes.profile,
            ];
            if (!allowedEmployeeRoutes.contains(loc) &&
                loc != AppRoutes.login) {
              return AppRoutes.dashboard;
            }
            break;
          case AppRole.admin:
          case AppRole.superAdmin:
            // Admins can navigate freely usually, but block from employee home if needed
            // Admins can navigate freely usually
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

      // Kiosk
      GoRoute(
        path: AppRoutes.kiosk,
        name: 'kiosk',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final workstationId = state.pathParameters['workstationId'];
          return MaterialPage(
            child: KioskScreen(workstationId: workstationId),
          );
        },
      ),

      // Entrance Kiosk
      GoRoute(
        path: AppRoutes.entrance,
        name: 'entrance',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: EntranceKioskScreen(),
        ),
      ),

      // Employee form (new) - Pushed on root nav to cover everything
      GoRoute(
        path: AppRoutes.employeeNew,
        name: 'employee-new',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: EmployeeFormScreen(),
        ),
      ),

      // Employee form (edit)
      GoRoute(
        path: AppRoutes.employeeEdit,
        name: 'employee-edit',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final employeeId = state.pathParameters['employeeId']!;
          return MaterialPage(
            child: EmployeeFormScreen(employeeId: employeeId),
          );
        },
      ),

      // Workstation form (new)
      GoRoute(
        path: AppRoutes.workstationNew,
        name: 'workstation-new',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: WorkstationFormScreen(),
        ),
      ),
      // Shift form (new)
      GoRoute(
        path: AppRoutes.shiftNew,
        name: 'shift-new',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: ShiftFormScreen(),
        ),
      ),

      // Shift form (edit)
      GoRoute(
        path: AppRoutes.shiftEdit,
        name: 'shift-edit',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final shiftId = state.pathParameters['shiftId']!;
          return MaterialPage(child: ShiftFormScreen(shiftId: shiftId));
        },
      ),

      // ── Fase 1: Task routes ──────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.taskNew,
        name: 'task-new',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: TaskFormScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.taskEdit,
        name: 'task-edit',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final taskId = state.pathParameters['taskId']!;
          return MaterialPage(child: TaskFormScreen(taskId: taskId));
        },
      ),

      // ── Fase 1: Leave routes ─────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.leaveNew,
        name: 'leave-new',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: LeaveRequestFormScreen(),
        ),
      ),

      // ── Fase 1: Alert log ────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.alertLog,
        name: 'alert-log',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: AlertLogScreen(),
        ),
      ),

      // ── Fase 2: Announcements ─────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.announcements,
        name: 'announcements',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: AnnouncementsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.announcementNew,
        name: 'announcement-new',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: AnnouncementFormScreen(),
        ),
      ),

      // ── Fase 2: Reports ───────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.reports,
        name: 'reports',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: ReportsScreen(),
        ),
      ),

      // ── Fase 3: Profile ───────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: ProfileScreen(),
        ),
      ),

      // ── Fase 3: Workstation Edit ──────────────────────────────────────────
      GoRoute(
        path: AppRoutes.workstationEdit,
        name: 'workstation-edit',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final workstationId = state.pathParameters['workstationId']!;
          return MaterialPage(
            child: WorkstationFormScreen(workstationId: workstationId),
          );
        },
      ),

      // Analytics detail
      GoRoute(
        path: AppRoutes.analyticsDetail,
        name: 'analytics-detail',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final employeeId = state.pathParameters['employeeId']!;
          return MaterialPage(
            child: EmployeeDetailAnalyticsScreen(employeeId: employeeId),
          );
        },
      ),

      // Stateful Bottom Nav Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithBottomNav(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard (All Roles)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDashboardKey,
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                name: 'dashboard',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: DashboardScreen(),
                ),
              ),
            ],
          ),

          // Branch 1: Employees (Admin)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorEmployeesKey,
            routes: [
              GoRoute(
                path: AppRoutes.employees,
                name: 'employees',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: EmployeesListScreen(),
                ),
              ),
            ],
          ),

          // Branch 2: Workstations (Admin)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorWorkstationsKey,
            routes: [
              GoRoute(
                path: AppRoutes.workstations,
                name: 'workstations',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: WorkstationsListScreen(),
                ),
              ),
            ],
          ),

          // Branch 3: History (Employee)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHistoryKey,
            routes: [
              GoRoute(
                path: AppRoutes.history,
                name: 'history',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ActivityHistoryScreen(),
                ),
              ),
            ],
          ),

          // Branch 4: Settings (All Roles)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSettingsKey,
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                name: 'settings',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SettingsScreen(),
                ),
              ),
            ],
          ),

          // Branch 5: Shifts (Admin)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorShiftsKey,
            routes: [
              GoRoute(
                path: AppRoutes.shifts,
                name: 'shifts',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ShiftsListScreen(),
                ),
              ),
            ],
          ),

          // Branch 6: Tasks (All roles)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorTasksKey,
            routes: [
              GoRoute(
                path: AppRoutes.tasks,
                name: 'tasks',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: TasksListScreen(),
                ),
              ),
            ],
          ),

          // Branch 7: Leaves (All roles)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorLeavesKey,
            routes: [
              GoRoute(
                path: AppRoutes.leaves,
                name: 'leaves',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: LeavesListScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Other minor screens that don't need Bottom Nav but aren't strictly root only modals:
      GoRoute(
        path: AppRoutes.analytics,
        name: 'analytics',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          child: AdminAnalyticsScreen(),
        ),
      ),

      GoRoute(
        path: AppRoutes.kioskWaiting,
        name: 'kiosk-waiting',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: KioskWaitingScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.homeEmployee,
        name: 'home-employee',
        redirect: (context, state) => AppRoutes.dashboard,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: HomeEmployeeScreen(),
        ),
      ),
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
        pageBuilder: (context, state) => const NoTransitionPage(
          child: MyHoursScreen(),
        ),
      ),

    ],
    errorPageBuilder: (context, state) => MaterialPage(
      child: RouteErrorScreen(error: state.error?.message ?? 'Ruta no encontrada'),
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

