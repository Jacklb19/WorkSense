import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/constants/app_routes.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:worksense_app/features/dashboard/presentation/providers/dashboard_provider.dart';

class KioskWaitingScreen extends ConsumerWidget {
  const KioskWaitingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workstationsAsync = ref.watch(workstationsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 2),
                ),
                child: const Icon(
                  Icons.settings_input_antenna,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                'CONFIGURAR DISPOSITIVO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Selecciona la función que este dispositivo cumplirá en la oficina.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 48),
              
              // Kiosco Central (Recepcion)
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.entrance),
                icon: const Icon(Icons.sensor_door),
                label: const Text('ESTABLECER COMO KIOSCO DE ENTRADA'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
              const SizedBox(height: 24),
              
              const Text('O asigna este dispositivo a un monitor personal:', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 16),
              
              // Monitor de Puesto
              workstationsAsync.when(
                data: (workstations) {
                  if (workstations.isEmpty) {
                     return const Text('No hay puestos creados en la base de datos.', style: TextStyle(color: AppColors.error), textAlign: TextAlign.center);
                  }
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: AppColors.cardDark,
                        hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Selecciona una cámara / puesto...', style: TextStyle(color: Colors.white54)),
                        ),
                        items: workstations.map((ws) => DropdownMenuItem(
                          value: ws.id,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(ws.name, style: const TextStyle(color: Colors.white)),
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
              ),
              
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(loginNotifierProvider.notifier).signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('CERRAR SESIÓN DEL DISPOSITIVO'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white54,
                    side: const BorderSide(color: Colors.white12),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
