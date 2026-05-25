import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/employee_dashboard_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/widgets/activity_event_tile.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/widgets/error_widget.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';

class ActivityHistoryScreen extends ConsumerStatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  ConsumerState<ActivityHistoryScreen> createState() =>
      _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState
    extends ConsumerState<ActivityHistoryScreen> {
  ActivityState? _filterState;

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentUserProvider).valueOrNull?.role;
    final eventsAsync = role == AppRole.employee
        ? ref.watch(employeeRecentEventsProvider)
        : ref.watch(recentEventsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Actividad'),
        actions: [
          IconButton(
            icon: Icon(
              _filterState != null
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
              color: _filterState != null ? AppColors.primary : null,
            ),
            onPressed: _showFilterSheet,
            tooltip: 'Filtrar por estado',
          ),
        ],
      ),
      body: eventsAsync.when(
        loading: () => const AppLoadingWidget(message: 'Cargando historial...'),
        error: (error, _) => AppErrorWidget(
          message:
              'No se pudo cargar el historial de actividad.\nVerifica tu conexión e intenta de nuevo.',
          icon: Icons.history_toggle_off,
          onRetry: () {
            ref.invalidate(employeeRecentEventsProvider);
            ref.invalidate(recentEventsStreamProvider);
          },
        ),
        data: (events) {
          final filtered = _filterState != null
              ? events.where((e) => e.state == _filterState).toList()
              : events;

          if (filtered.isEmpty) {
            return AppEmptyState(
              icon: hasFilter
                  ? Icons.search_off
                  : Icons.history_toggle_off,
              title: hasFilter ? 'Sin resultados' : 'Sin eventos registrados',
            );
          }

          return Column(
            children: [
              if (_filterState != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingXxl,
                    vertical: AppDimensions.spacingMd,
                  ),
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(
                          '${_filterState!.emoji} ${_filterState!.label}',
                        ),
                        selected: true,
                        onSelected: (_) =>
                            setState(() => _filterState = null),
                        deleteIcon:
                            const Icon(Icons.close, size: AppDimensions.iconXs),
                        onDeleted: () =>
                            setState(() => _filterState = null),
                      ),
                      const SizedBox(width: AppDimensions.spacingMd),
                      Text(
                        '${filtered.length} eventos',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: AppDimensions.fontCaption,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: AppDimensions.dividerIndent,
                    color: AppColors.divider,
                  ),
                  itemBuilder: (context, index) => ActivityEventTile(
                    event: filtered[index],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool get hasFilter => _filterState != null;

  void _showFilterSheet() {
    showModalBottomSheet<ActivityState?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusModal)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppDimensions.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtrar por estado',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimensions.spacingXxl),
            ListTile(
              leading: const Text('🔵', style: TextStyle(fontSize: AppDimensions.fontHeadline)),
              title: const Text('Todos los estados'),
              selected: _filterState == null,
              onTap: () {
                setState(() => _filterState = null);
                Navigator.pop(ctx);
              },
            ),
            ...ActivityState.values.map(
              (s) => ListTile(
                leading: Text(
                  s.emoji,
                  style: const TextStyle(fontSize: AppDimensions.fontHeadline),
                ),
                title: Text(s.label),
                selected: _filterState == s,
                selectedTileColor: s.color.withAlpha(20),
                onTap: () {
                  setState(() => _filterState = s);
                  Navigator.pop(ctx, s);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
