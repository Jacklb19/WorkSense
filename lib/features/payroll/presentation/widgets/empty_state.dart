import 'package:flutter/material.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onCreateTap;
  const EmptyState({super.key, required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.payments_outlined,
              size: 64, color: context.appOnSurfaceDisabled),
          const SizedBox(height: AppDimensions.spacingXxl),
          Text(
            'Sin períodos de nómina',
            style: theme.textTheme.titleSmall?.copyWith(color: context.appOnSurfaceSecondary),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          Text(
            'Crea el primer período para calcular\nla nómina de tu equipo.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: context.appOnSurfaceDisabled),
          ),
          const SizedBox(height: AppDimensions.spacingXxl),
          FilledButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add),
            label: const Text('Crear período'),
          ),
        ],
      ),
    );
  }
}
