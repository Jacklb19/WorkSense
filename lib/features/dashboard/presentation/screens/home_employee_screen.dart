import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/shared/providers/auth_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

class HomeEmployeeScreen extends ConsumerWidget {
  const HomeEmployeeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Panel de Empleado'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: Center(
        child: userState.when(
          data: (currentUser) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person, size: 80, color: Colors.blueAccent),
                const SizedBox(height: 16),
                Text(
                  'Bienvenido',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (currentUser.user?.email != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    currentUser.user!.email!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
                const SizedBox(height: 24),
                const Text('Aquí verás tu horario y estado de actividad.'),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Text('Error: $error'),
        ),
      ),
    );
  }
}
