import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/l10n/app_localizations.dart';
import 'package:worksense_app/core/navigation/app_bottom_nav_bar.dart';
import 'package:worksense_app/core/navigation/nav_destination.dart';
import 'package:worksense_app/core/navigation/nav_destinations.dart';
import 'package:worksense_app/features/leaves/presentation/providers/leaves_provider.dart';
import 'package:worksense_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

class ScaffoldWithBottomNav extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithBottomNav({
    super.key,
    required this.navigationShell,
  });

  // ── Branch ↔ UI index mapping ──────────────────────────────────────────────
  // Shell branches:
  //   0: Dashboard        (all roles)
  //   1: Employees        (admin)
  //   2: Workstations     (admin)
  //   3: History          (employee)
  //   4: Settings         (all roles)
  //   5: Shifts           (admin)
  //   6: Tasks            (all roles)
  //   7: Leaves           (all roles)
  //
  // Admin UI:    0→0, 1→1, 2→2, 3→6(Tasks), 4→7(Leaves), 5→5(Shifts), 6→4(Settings)
  // Employee UI: 0→0, 1→6(Tasks), 2→7(Leaves), 3→3(History), 4→4(Settings)

  // ✅ Métodos estáticos fuera de build() — no se recrean en cada rebuild.
  static int _uiIndex(bool admin, int branchIndex) {
    if (admin) {
      switch (branchIndex) {
        case 0: return 0;
        case 1: return 1;
        case 2: return 2;
        case 6: return 3; // Tasks
        case 7: return 4; // Leaves
        case 5: return 5; // Shifts
        case 4: return 6; // Settings
        default: return 0;
      }
    } else {
      switch (branchIndex) {
        case 0: return 0;
        case 6: return 1; // Tasks
        case 7: return 2; // Leaves
        case 3: return 3; // History
        case 4: return 4; // Settings
        default: return 0;
      }
    }
  }

  static int _branchIndex(bool admin, int uiIndex) {
    if (admin) {
      switch (uiIndex) {
        case 0: return 0;
        case 1: return 1;
        case 2: return 2;
        case 3: return 6; // Tasks
        case 4: return 7; // Leaves
        case 5: return 5; // Shifts
        case 6: return 4; // Settings
        default: return 0;
      }
    } else {
      switch (uiIndex) {
        case 0: return 0;
        case 1: return 6; // Tasks
        case 2: return 7; // Leaves
        case 3: return 3; // History
        case 4: return 4; // Settings
        default: return 0;
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(currentUserProvider);
    final user = userState.valueOrNull;

    final bool isAdmin =
        user?.role == AppRole.admin || user?.role == AppRole.superAdmin;

    // ── Badge counts ───────────────────────────────────────────────────────
    final l10n = AppLocalizations.of(context);
    final List<NavDestination> destinations;
    if (isAdmin) {
      final pendingTasks = ref.watch(companyPendingTasksCountProvider);
      final pendingLeaves = ref.watch(pendingLeavesCountProvider);
      final base = adminDestinations(l10n);
      destinations = [
        base[0], base[1], base[2],
        base[3].withBadge(pendingTasks),
        base[4].withBadge(pendingLeaves),
        base[5], base[6],
      ];
    } else {
      final pendingTasks = ref.watch(myPendingTasksCountProvider);
      final pendingLeaves = ref.watch(myPendingLeavesCountProvider);
      final base = employeeDestinations(l10n);
      destinations = [
        base[0],
        base[1].withBadge(pendingTasks),
        base[2].withBadge(pendingLeaves),
        base[3], base[4],
      ];
    }

    final uiCurrentIndex = _uiIndex(isAdmin, navigationShell.currentIndex);

    return PopScope(
      canPop: uiCurrentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          navigationShell.goBranch(
              0, initialLocation: 0 == navigationShell.currentIndex);
        }
      },
      child: Scaffold(
        body: SafeArea(child: navigationShell),
        bottomNavigationBar: AppBottomNavBar(
          destinations: destinations,
          currentIndex: uiCurrentIndex,
          onDestinationSelected: (int tabIndex) {
            final targetBranch = _branchIndex(isAdmin, tabIndex);
            navigationShell.goBranch(
              targetBranch,
              initialLocation: targetBranch == navigationShell.currentIndex,
            );
          },
        ),
      ),
    );
  }
}
