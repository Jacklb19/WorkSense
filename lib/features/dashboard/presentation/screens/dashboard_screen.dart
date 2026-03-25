import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import 'package:worksense_app/features/dashboard/presentation/screens/employee_dashboard_screen.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserState = ref.watch(currentUserProvider);

    return currentUserState.when(
      data: (user) {
        final role = user.role;
        final isAdmin = role == AppRole.admin || role == AppRole.superAdmin;
        
        if (isAdmin) {
          return const AdminDashboardScreen();
        } else {
          return const EmployeeDashboardScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}
