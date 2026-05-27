import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/l10n/app_localizations.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_colors.dart';
import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

class HomeEmployeeScreen extends ConsumerWidget {
  const HomeEmployeeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myEmployeePanel),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(loginNotifierProvider.notifier).signOut();
            },
            tooltip: l10n.logout,
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
                  l10n.welcome,
                  style: theme.textTheme.headlineMedium,
                ),
                if (currentUser.user?.email != null) ...[
                  const SizedBox(height: AppDimensions.spacingMd),
                  Text(
                    currentUser.user!.email!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: AppDimensions.spacing32),
                Text(
                  l10n.scheduleAndActivityHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.appColors.textSecondary,
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
