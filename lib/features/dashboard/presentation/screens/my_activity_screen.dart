import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/core/l10n/app_localizations.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_theme_colors.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/employee_dashboard_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/widgets/activity_event_tile.dart';
import 'package:worksense_app/shared/widgets/error_widget.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';
import 'package:worksense_app/shared/widgets/styled/app_empty_state.dart';

class MyActivityScreen extends ConsumerWidget {
  const MyActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentEventsAsync = ref.watch(employeeRecentEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.activityLog,
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        centerTitle: false,
      ),
      body: recentEventsAsync.when(
        loading: () => AppLoadingWidget(message: context.l10n.loadingActivity),
        error: (error, _) => AppErrorWidget(
          message: context.l10n.errorLoadingActivityMsg,
          icon: Icons.history_toggle_off,
          onRetry: () => ref.invalidate(employeeRecentEventsProvider),
        ),
        data: (events) {
          if (events.isEmpty) {
            return AppEmptyState(
              icon: Icons.history_toggle_off,
              title: context.l10n.noRecordsTitle,
              subtitle: context.l10n.noRecordsSubtitle,
              iconColor: context.appColors.textDisabled,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: events.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) => ActivityEventTile(event: events[index]),
          );
        },
      ),
    );
  }
}

class _EmptyActivityView extends StatelessWidget {
  const _EmptyActivityView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_toggle_off,
                size: 40,
                color: context.appColors.textDisabled,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'SIN REGISTROS AÚN',
              style: TextStyle(
                color: context.appColors.textDisabled,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Tu actividad reciente aparecerá aquí\ncuando comiences a trabajar.',
              style: TextStyle(color: context.appColors.textDisabled, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
