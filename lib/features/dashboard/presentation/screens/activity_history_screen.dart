import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/widgets/activity_event_tile.dart';
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
    final eventsAsync = ref.watch(recentEventsStreamProvider);

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
        loading: () => const AppLoadingWidget(),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (events) {
          final filtered = _filterState != null
              ? events.where((e) => e.state == _filterState).toList()
              : events;

          if (filtered.isEmpty) {
            return _EmptyHistoryView(
              hasFilter: _filterState != null,
              onClearFilter: () =>
                  setState(() => _filterState = null),
            );
          }

          return Column(
            children: [
              // Filter chip strip
              if (_filterState != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
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
                            const Icon(Icons.close, size: 16),
                        onDeleted: () =>
                            setState(() => _filterState = null),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${filtered.length} eventos',
                        style: const TextStyle(
                          color: AppColors.grey500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

              // List
              Expanded(
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 72,
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

  void _showFilterSheet() {
    showModalBottomSheet<ActivityState?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtrar por estado',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // All states option
            ListTile(
              leading: const Text('🔵', style: TextStyle(fontSize: 24)),
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
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(s.label),
                selected: _filterState == s,
                selectedTileColor: s.color.withValues(alpha: 0.08),
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

class _EmptyHistoryView extends StatelessWidget {
  final bool hasFilter;
  final VoidCallback? onClearFilter;

  const _EmptyHistoryView({
    required this.hasFilter,
    this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.history_toggle_off,
            size: 64,
            color: AppColors.grey300,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'Sin resultados' : 'Sin eventos registrados',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.grey500,
                ),
          ),
          if (hasFilter && onClearFilter != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onClearFilter,
              child: const Text('Quitar filtro'),
            ),
          ],
        ],
      ),
    );
  }
}
