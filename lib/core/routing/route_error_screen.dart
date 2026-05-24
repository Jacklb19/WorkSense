import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/theme/app_colors.dart';

class RouteErrorScreen extends StatelessWidget {
  final String error;

  const RouteErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página no encontrada')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: AppDimensions.iconEmptyState, color: AppColors.grey500),
            const SizedBox(height: AppDimensions.spacingXxl),
            Text(error),
            const SizedBox(height: AppDimensions.spacingXxl),
            FilledButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Ir al dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
