import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';

class HomeEmployeeScreen extends ConsumerWidget {
  const HomeEmployeeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.myEmployeePanel),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(loginNotifierProvider.notifier).signOut();
            },
            tooltip: AppStrings.logout,
          ),
        ],
      ),
      body: Center(
        child: userState.when(
          data: (currentUser) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacing24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withAlpha(50),
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: AppDimensions.iconHero,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacing24),
                Text(
                  AppStrings.welcome,
                  style: theme.textTheme.headlineMedium,
                ),
                if (currentUser.user?.email != null) ...[
                  const SizedBox(height: AppDimensions.spacingMd),
                  Text(
                    currentUser.user!.email!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: AppDimensions.spacing32),
                Text(
                  AppStrings.scheduleAndActivityHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            );
          },
          loading: () =>
              const CircularProgressIndicator(color: AppColors.primary),
          error: (error, _) => Text(
            'Error: $error',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}
