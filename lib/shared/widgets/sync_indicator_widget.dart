import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/shared/providers/connectivity_provider.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';

class SyncIndicatorWidget extends ConsumerWidget {
  const SyncIndicatorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar conectividad
    final isOnline = ref.watch(isOnlineProvider);
    
    // Escuchar conteo de eventos (usamos el provider individual por simplicidad)
    final pendingCount = ref.watch(pendingEventCountProvider); 

    if (!isOnline) {
      // 3. Ícono de nube roja si está offline
      return const Tooltip(
        message: 'Modo Offline',
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Icon(Icons.cloud_off, color: Color(0xFFEA4335)),
        ),
      );
    }

    if (pendingCount > 0) {
      // 2. Ícono de nube naranja con badge si hay pendientes
      // 4. El badge muestra cuántos eventos hay
      return Tooltip(
        message: '$pendingCount eventos pendientes de sincronización',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.cloud_upload, color: Color(0xFFFF6D00)),
              Positioned(
                right: 0,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    pendingCount > 99 ? '99+' : '$pendingCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 1. Ícono de nube verde si está online y sin pendientes
    return const Tooltip(
      message: 'Online y Sincronizado',
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Icon(Icons.cloud_done, color: Color(0xFF34A853)),
      ),
    );
  }
}
