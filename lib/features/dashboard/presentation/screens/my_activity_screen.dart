import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/styled/app_empty_state.dart';
import '../../presentation/providers/employee_dashboard_provider.dart';
import '../../presentation/widgets/activity_event_tile.dart';

class MyActivityScreen extends ConsumerWidget {
  const MyActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentEventsAsync = ref.watch(employeeRecentEventsProvider);

    return Scaffold(
      body: recentEventsAsync.when(
        loading: () => const AppLoadingWidget(),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (events) {
          if (events.isEmpty) {
            return const AppEmptyState(
              icon: Icons.history_toggle_off,
              title: 'SIN REGISTROS',
              subtitle: 'La actividad reciente aparecera en este log.',
              iconColor: AppColors.textDisabled,
            );
          }

          return CustomScrollView(
            slivers: [
              const SliverAppBar(
                pinned: true,
                title: Text(
                  'REGISTRO DE ACTIVIDAD',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                centerTitle: false,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(AppDimensions.spacingXxl),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        ActivityEventTile(event: events[index]),
                    childCount: events.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
