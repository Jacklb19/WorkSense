import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_dimensions.dart';
import '../constants/app_routes.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme_colors.dart';

class RouteErrorScreen extends StatelessWidget {
  final String error;

  const RouteErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ac = context.appColors;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.pageNotFound)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacing24),
                decoration: BoxDecoration(
                  color: AppColors.errorSoft,
                  border: Border.all(
                    color: AppColors.error.withAlpha(80),
                  ),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusCard),
                ),
                child: const Icon(
                  Icons.map_outlined,
                  size: AppDimensions.iconEmptyState,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppDimensions.spacing24),
              Text(
                error,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: ac.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.spacing40),
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.dashboard),
                icon: const Icon(Icons.home_outlined),
                label: Text(context.l10n.goToDashboard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
