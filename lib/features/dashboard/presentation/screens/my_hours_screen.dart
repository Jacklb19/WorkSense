import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart';

class MyHoursScreen extends ConsumerWidget {
  const MyHoursScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Horas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(loginNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: const Center(child: Text('Mis horas — Próximamente')),
    );
  }
}
