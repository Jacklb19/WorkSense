import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:worksense_app/features/workstations/presentation/providers/workstations_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/widgets/loading_widget.dart';

class KioskWaitingScreen extends ConsumerWidget {
  const KioskWaitingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workstationsAsync = ref.watch(workstationsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.settings_input_antenna_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'CONFIGURAR DISPOSITIVO',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Selecciona el modo de operación para este dispositivo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).hintColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Entrance kiosk button
              FilledButton.icon(
                onPressed: () => context.go('/entrance'),
                icon: const Icon(Icons.sensor_door_rounded),
                label: const Text('KIOSCO DE ENTRADA'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Divider(color: Theme.of(context).hintColor.withOpacity(0.2)),
              const SizedBox(height: 16),

              Text(
                'O selecciona una estación de monitoreo personal:',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).hintColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Workstation selector
              workstationsAsync.when(
                loading: () =>
                    const SizedBox(height: 52, child: AppLoadingWidget()),
                error: (e, _) => Text(
                  'Error al cargar estaciones: $e',
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                data: (workstations) {
                  if (workstations.isEmpty) {
                    return Text(
                      'No hay estaciones registradas',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).hintColor,
                      ),
                    );
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).hintColor.withOpacity(0.2),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Seleccionar estación...'),
                        items: workstations.map((ws) {
                          return DropdownMenuItem(
                            value: ws.id,
                            child: Text(
                              ws.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id != null) context.go('/kiosk/$id');
                        },
                      ),
                    ),
                  );
                },
              ),

              const Spacer(),

              // Logout
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(loginNotifierProvider.notifier).signOut(),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('CERRAR SESIÓN DEL DISPOSITIVO'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).hintColor,
                  side: BorderSide(
                    color: Theme.of(context).hintColor.withOpacity(0.3),
                  ),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
