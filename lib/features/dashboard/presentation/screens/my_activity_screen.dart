import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart';

class MyActivityScreen extends ConsumerWidget {
  const MyActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Actividad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(loginNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: const Center(child: Text('Panel de empleado — Próximamente')),
    );
  }
}
