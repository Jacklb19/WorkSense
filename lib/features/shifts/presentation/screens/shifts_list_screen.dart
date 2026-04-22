import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/theme/app_text_styles.dart';
import 'package:worksense_app/features/shifts/presentation/providers/shifts_provider.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';
import 'package:intl/intl.dart';

class ShiftsListScreen extends ConsumerWidget {
  const ShiftsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(shiftsStreamProvider);
    final employeesAsync = ref.watch(employeesStreamProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Turnos',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push('/shift_form'),
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
          ),
        ],
      ),
      body: shiftsAsync.when(
        data: (shifts) {
          if (shifts.isEmpty) {
            return const Center(
              child: Text(
                'No hay turnos registrados',
                style: TextStyle(color: AppColors.grey500),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: shifts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final shift = shifts[index];
              
              // Get employee name
              String employeeName = 'Empleado Desconocido';
              employeesAsync.whenData((employees) {
                final emp = employees.where((e) => e.id == shift.employeeId).firstOrNull;
                if (emp != null) employeeName = emp.name;
              });

              final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
              final startStr = dateFormat.format(shift.startTime);
              final endStr = dateFormat.format(shift.endTime);

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey200),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    employeeName,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.login_rounded, size: 14, color: AppColors.stateWorking),
                            const SizedBox(width: 4),
                            Text('Inicio: $startStr', style: AppTextStyles.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.logout_rounded, size: 14, color: AppColors.error),
                            const SizedBox(width: 4),
                            Text('Fin: $endStr', style: AppTextStyles.bodySmall),
                          ],
                        ),
                        if (shift.notes != null && shift.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Notas: ${shift.notes}',
                            style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ]
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    onPressed: () {
                      ref.read(shiftFormNotifierProvider.notifier).deleteShift(shift.id);
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, stack) => Center(
          child: Text('Error: $error', style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}
