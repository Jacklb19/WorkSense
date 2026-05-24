import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/data/repositories/employee_repository_impl.dart';
import 'package:worksense_app/domain/entities/app_role.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/domain/repositories/employee_repository.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';
import 'package:worksense_app/data/datasources/remote/supabase_datasource.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

import 'package:worksense_app/core/constants/app_constants.dart';

// ── Repository Provider ───────────────────────────────────────────────────────

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncRepo = ref.watch(syncRepositoryProvider);
  return EmployeeRepositoryImpl(db, syncRepo);
});

// ── Employee List ─────────────────────────────────────────────────────────────

final employeesStreamProvider = StreamProvider<List<Employee>>((ref) {
  final repo = ref.watch(employeeRepositoryProvider);
  return repo.watchEmployees();
});

final employeesProvider = FutureProvider<List<Employee>>((ref) async {
  final repo = ref.watch(employeeRepositoryProvider);
  return repo.getEmployees();
});

Employee _mapRemoteEmployee(Map<String, dynamic> json) {
  return Employee(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? '',
    lastName: (json['last_name'] as String?) ?? '',
    email: (json['email'] as String?) ?? '',
    role: AppRoleX.fromRaw(json['role']),
    companyId: json['company_id'] as String,
    createdAt:
        DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
    shiftId: json['shift_id'] as String?,
  );
}

Employee _mergeEmployee(Employee? local, Employee remote) {
  if (local == null) return remote;
  return local.copyWith(
    name: remote.name.isNotEmpty ? remote.name : local.name,
    lastName: remote.lastName.isNotEmpty ? remote.lastName : local.lastName,
    email: remote.email.isNotEmpty ? remote.email : local.email,
    role: remote.role,
    companyId: remote.companyId,
    createdAt: remote.createdAt,
    shiftId: remote.shiftId,
  );
}

// Admin-specific provider that merges local Drift + remote Supabase
final adminEmployeesProvider = FutureProvider<List<Employee>>((ref) async {
  final repo = ref.watch(employeeRepositoryProvider);
  final supabase = ref.watch(supabaseDataSourceProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  final companyId = currentUser?.companyId ?? AppConstants.defaultCompanyId;

  final merged = <String, Employee>{};

  try {
    final localEmployees = await repo.getEmployees();
    for (final employee in localEmployees) {
      merged[employee.id] = employee;
    }
  } catch (_) {
    // Keep remote as fallback.
  }

  try {
    final remoteEmployees = await supabase.fetchAllEmployees(companyId);
    for (final row in remoteEmployees) {
      final remoteEmployee = _mapRemoteEmployee(row);
      merged[remoteEmployee.id] =
          _mergeEmployee(merged[remoteEmployee.id], remoteEmployee);
    }
  } catch (_) {
    if (merged.isEmpty) rethrow;
  }

  final employees = merged.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return employees;
});

// ── Employee Form State ───────────────────────────────────────────────────────

class EmployeeFormState {
  final bool isLoading;
  final bool saved;
  final String? errorMessage;

  const EmployeeFormState({
    this.isLoading = false,
    this.saved = false,
    this.errorMessage,
  });

  EmployeeFormState copyWith({
    bool? isLoading,
    bool? saved,
    String? errorMessage,
  }) {
    return EmployeeFormState(
      isLoading: isLoading ?? this.isLoading,
      saved: saved ?? this.saved,
      errorMessage: errorMessage,
    );
  }
}

class EmployeeFormNotifier extends StateNotifier<EmployeeFormState> {
  final EmployeeRepository _localRepo;
  final SupabaseDataSource _supabase;
  final Ref _ref;

  EmployeeFormNotifier(this._localRepo, this._supabase, this._ref)
      : super(const EmployeeFormState());

  Future<void> saveEmployee({
    required String name,
    required String lastName,
    required String email,
    required String password,
    required AppRole role,
    String? shiftId,
    String companyId = AppConstants.defaultCompanyId,
    String? existingId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, saved: false);

    final currentUser = _ref.read(currentUserProvider).value;
    final effectiveCompanyId = companyId != AppConstants.defaultCompanyId 
        ? companyId 
        : (currentUser?.companyId ?? AppConstants.defaultCompanyId);

    try {
      if (existingId == null) {
        // Creating NEW employee via Edge Function
        await _supabase.createEmployeeWithAuth({
          'email': email,
          'password': password,
          'name': name,
          'lastName': lastName,
          'role': role.metadataValue,
          'companyId': effectiveCompanyId,
          'shiftId': shiftId,
        });
      } else {
        await _supabase.updateEmployeeWithAuth({
          'id': existingId,
          'email': email,
          'name': name,
          'lastName': lastName,
          'role': role.metadataValue,
          'companyId': effectiveCompanyId,
          'shiftId': shiftId,
        });
      }

      await _ref.read(syncNotifierProvider.notifier).sync();
      _ref.invalidate(adminEmployeesProvider);

      state = state.copyWith(isLoading: false, saved: true);
    } catch (e) {
      String errorMessage = 'Error al guardar empleado: $e';
      if (e.toString().toLowerCase().contains('socket') || 
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('offline')) {
        errorMessage = 'Sin conexión a internet. La creación de usuarios requiere conexión al servidor.';
      }
      
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
      );
    }
  }

  Future<void> deleteEmployee(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _localRepo.deleteEmployee(id);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al eliminar empleado: $e',
      );
    }
  }

  void reset() {
    state = const EmployeeFormState();
  }
}

final employeeFormNotifierProvider =
    StateNotifierProvider<EmployeeFormNotifier, EmployeeFormState>((ref) {
  final repo = ref.watch(employeeRepositoryProvider);
  final supabase = ref.watch(supabaseDataSourceProvider);
  return EmployeeFormNotifier(repo, supabase, ref);
});
