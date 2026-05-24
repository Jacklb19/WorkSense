import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(currentUserProvider);
    final user = userState.valueOrNull;

    final bool isAdmin =
        user?.role == AppRole.admin || user?.role == AppRole.superAdmin;

    // ── Badge counts ───────────────────────────────────────────────────────
    final List<NavDestination> destinations;
    if (isAdmin) {
      final pendingTasks = ref.watch(companyPendingTasksCountProvider);
      final base = adminDestinations;
      // Admin UI: 0=Dashboard, 1=Employees, 2=Workstations, 3=Tasks, 4=Shifts, 5=Settings
      destinations = [
        base[0], base[1], base[2],
        base[3].withBadge(pendingTasks),
        base[4], base[5],
      ];
    } else {
      final pendingTasks = ref.watch(myPendingTasksCountProvider);
      final pendingLeaves = ref.watch(myPendingLeavesCountProvider);
      final base = employeeDestinations;
      // Employee UI: 0=Home, 1=Tasks, 2=Leaves, 3=Activity, 4=Settings
      destinations = [
        base[0],
        base[1].withBadge(pendingTasks),
        base[2].withBadge(pendingLeaves),
        base[3], base[4],
      ];
    }

    // ── Branch ↔ UI index mapping ──────────────────────────────────────────
    // Shell branches:
    //   0: Dashboard        (all roles)
    //   1: Employees        (admin)
    //   2: Workstations     (admin)
    //   3: History          (employee)
    //   4: Settings         (all roles)
    //   5: Shifts           (admin)
    //   6: Tasks            (all roles)  ← NEW
    //   7: Leaves           (all roles)  ← NEW
    //
    // Admin UI: 0→0, 1→1, 2→2, 3→6, 4→5, 5→4
    // Employee UI: 0→0, 1→6, 2→7, 3→3, 4→4

    int getUIIndex(bool admin, int branchIndex) {
      if (admin) {
        switch (branchIndex) {
          case 0: return 0;
          case 1: return 1;
          case 2: return 2;
          case 6: return 3;
          case 5: return 4;
          case 4: return 5;
          default: return 0;
        }
      } else {
        switch (branchIndex) {
          case 0: return 0;
          case 6: return 1;
          case 7: return 2;
          case 3: return 3;
          case 4: return 4;
          default: return 0;
        }
      }
    }

    int getBranchIndex(bool admin, int uiIndex) {
      if (admin) {
        switch (uiIndex) {
          case 0: return 0;
          case 1: return 1;
          case 2: return 2;
          case 3: return 6;
          case 4: return 5;
          case 5: return 4;
          default: return 0;
        }
      } else {
        switch (uiIndex) {
          case 0: return 0;
          case 1: return 6;
          case 2: return 7;
          case 3: return 3;
          case 4: return 4;
          default: return 0;
        }
      }
    }

    final uiCurrentIndex =
        getUIIndex(isAdmin, navigationShell.currentIndex);

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
            final targetBranch = getBranchIndex(isAdmin, tabIndex);
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
