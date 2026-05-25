import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/navigation/app_bottom_nav_bar.dart';
import 'package:worksense_app/core/navigation/nav_destinations.dart';
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

    // Default to employee if loading or error to prevent crashes during auth redirect
    final bool isAdmin = user?.role == AppRole.admin || user?.role == AppRole.superAdmin;
    final destinations = isAdmin ? adminDestinations : employeeDestinations;

    // Map GoRouter's branch index to our UI's destination index
    int getUIIndex(bool admin, int branchIndex) {
      if (admin) {
        // Admin branches: 0 (Dashboard), 1 (Employees), 2 (Workstations), 5 (Shifts), 4 (Settings)
        if (branchIndex == 0) return 0;
        if (branchIndex == 1) return 1;
        if (branchIndex == 2) return 2;
        if (branchIndex == 5) return 3;
        if (branchIndex == 4) return 4;
        return 0;
      } else {
        // Employee branches: 0 (Dashboard), 3 (History), 4 (Settings)
        if (branchIndex == 0) return 0;
        if (branchIndex == 3) return 1;
        if (branchIndex == 4) return 2;
        return 0;
      }
    }

    int getBranchIndex(bool admin, int uiIndex) {
      if (admin) {
        if (uiIndex == 0) return 0;
        if (uiIndex == 1) return 1;
        if (uiIndex == 2) return 2;
        if (uiIndex == 3) return 5;
        if (uiIndex == 4) return 4;
        return 0;
      } else {
        if (uiIndex == 0) return 0;
        if (uiIndex == 1) return 3;
        if (uiIndex == 2) return 4;
        return 0;
      }
    }

    final uiCurrentIndex = getUIIndex(isAdmin, navigationShell.currentIndex);

    return PopScope(
      canPop: uiCurrentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          // Send back to branch 0
          navigationShell.goBranch(0, initialLocation: 0 == navigationShell.currentIndex);
        }
      },
      child: Scaffold(
        body: navigationShell,
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
