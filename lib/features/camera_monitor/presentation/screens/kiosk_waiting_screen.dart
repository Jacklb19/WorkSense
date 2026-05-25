import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';
import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:worksense_app/shared/widgets/loading_indicator.dart';

class KioskWaitingScreen extends ConsumerWidget {
  const KioskWaitingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workstationsAsync = ref.watch(workstationsStreamProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacing32),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.settings_input_antenna,
                  size: AppDimensions.iconEmptyStateLg,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacing48),
              Text(
                AppStrings.configureDevice,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: AppDimensions.fontHeadline,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXxl),
              Text(
                AppStrings.selectDeviceFunction,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.white60, fontSize: AppDimensions.fontBodyMd, height: 1.5),
              ),
              const SizedBox(height: AppDimensions.spacing48),
              
              // Kiosco Central (Recepcion)
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.entrance),
                icon: const Icon(Icons.sensor_door),
                label: Text(AppStrings.setAsEntryKiosk),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing20),
                ),
              ),
              const SizedBox(height: AppDimensions.spacing24),
              
              Text(AppStrings.assignMonitor, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.white60)),
              const SizedBox(height: AppDimensions.spacingXxl),
              
              // Monitor de Puesto
              workstationsAsync.when(
                data: (workstations) {
                  if (workstations.isEmpty) {
                     return Text(AppStrings.noWorkstationsRegistered, style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center);
                  }
                  return Container(
                    decoration: BoxDecoration(
                      color: context.appCard,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: context.appCard,
                        hint: Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl),
                          child: Text(AppStrings.selectCamera, style: const TextStyle(color: AppColors.white54)),
                        ),
                        items: workstations.map((ws) => DropdownMenuItem(
                          value: ws.id,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl),
                            child: Text(ws.name, style: const TextStyle(color: AppColors.white)),
                          ),
                        )).toList(),
                        onChanged: (id) {
                          if (id != null) {
                            context.push('/kiosk/$id');
                          }
                        },
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: AppLoadingIndicator()),
                error: (e, _) => Text('Error: $e', style: const TextStyle(color: AppColors.error)),
              ),
              
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(loginNotifierProvider.notifier).signOut(),
                  icon: const Icon(Icons.logout),
                  label: Text(AppStrings.logoutDevice),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white54,
                    side: const BorderSide(color: AppColors.white12),
                    padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXxl),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacing24),
            ],
          ),
        ),
      ),
    );
  }
}