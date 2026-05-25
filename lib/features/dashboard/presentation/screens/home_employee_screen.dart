import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_spacing.dart';
import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/widgets/loading_indicator.dart';

class HomeEmployeeScreen extends ConsumerWidget {
  const HomeEmployeeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(currentUserProvider);

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
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: AppSpacing.formMaxWidth(context)),
          child: userState.when(
            data: (currentUser) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                const Icon(Icons.person, size: AppDimensions.iconLogo, color: AppColors.primaryLight),
                const SizedBox(height: AppDimensions.spacingXxl),
                Text(
                  AppStrings.welcomeGreeting,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (currentUser.user?.email != null) ...[
                  const SizedBox(height: AppDimensions.spacingMd),
                  Text(
                    currentUser.user!.email!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
                const SizedBox(height: AppDimensions.spacing24),
                const Text(AppStrings.scheduleAndActivityHint),
              ],
            );
          },
          loading: () => const AppLoadingIndicator(),
          error: (error, _) => Text('Error: $error'),
        ),
      ),
    ),
  );
}