import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/current_user_provider.dart';
import 'admin_dashboard_screen.dart';
import 'employee_dashboard_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserState = ref.watch(currentUserProvider);

    return currentUserState.when(
      data: (user) {
        final role = user.role;
        final isAdmin =
            role == AppRole.admin || role == AppRole.superAdmin;

        if (isAdmin) {
          return const AdminDashboardScreen();
        } else {
          return const EmployeeDashboardScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Text(
            'Error: $error',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}
