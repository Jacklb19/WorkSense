import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/features/workstations/presentation/providers/workstations_provider.dart';
import 'package:worksense_app/shared/widgets/async_value_widget.dart';

class WorkstationsListScreen extends ConsumerWidget {
  const WorkstationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workstationsAsync = ref.watch(workstationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estaciones de Trabajo'),
      ),
      body: AsyncValueWidget(
        value: workstationsAsync,
        builder: (workstations) {
          if (workstations.isEmpty) {
            return const Center(
              child: Text(
                'No hay estaciones de trabajo registradas.',
                style: TextStyle(color: AppColors.grey500),
              ),
            );
          }

          return ListView.builder(
            itemCount: workstations.length,
            itemBuilder: (context, index) {
              final workstation = workstations[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    workstation.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Device ID: ${workstation.deviceId ?? 'N/A'}\n'
                    'Compañía: ${workstation.companyId}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () => _confirmDelete(context, ref, workstation.id, workstation.name),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/workstations/new'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Estación'),
        content: Text('¿Seguro que deseas eliminar la estación "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      try {
        await ref.read(deleteWorkstationUseCaseProvider)(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estación eliminada (Sincronización pendiente)')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
