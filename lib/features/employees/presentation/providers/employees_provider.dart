import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:worksense_app/data/repositories/employee_repository_impl.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/domain/repositories/employee_repository.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart' hide supabaseDataSourceProvider;
import 'package:worksense_app/data/datasources/remote/supabase_datasource.dart';
import 'package:worksense_app/shared/providers/auth_provider.dart';

import '../../../../core/constants/app_constants.dart';

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

// Admin-specific provider that fetches directly from Supabase
final adminEmployeesProvider = FutureProvider<List<Employee>>((ref) async {
  final supabase = ref.watch(supabaseDataSourceProvider);
  
  // Asumiendo que DefaultCompanyId es usado por ahora.
  // Podrías leer el companyId del current_user_provider si tienes multi-tenant
  final data = await supabase.fetchAllEmployees(AppConstants.defaultCompanyId);
  
  return data.map((json) {
    return Employee(
      id: json['id'] as String,
      name: '${json['name']} ${json['last_name'] ?? ''}'.trim(),
      companyId: json['company_id'] as String,
      createdAt: DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
    );
  }).toList();
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

  EmployeeFormNotifier(this._localRepo, this._supabase)
      : super(const EmployeeFormState());

  Future<void> saveEmployee({
    required String name,
    required String lastName,
    required String email,
    required String password,
    required String role,
    String companyId = AppConstants.defaultCompanyId,
    String? existingId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, saved: false);

    try {
      if (existingId == null) {
        // Creating NEW employee via Edge Function
        await _supabase.createEmployeeWithAuth({
          'email': email,
          'password': password,
          'name': name,
          'lastName': lastName,
          'role': role,
          'companyId': companyId,
        });
      } else {
        // Editing existing: usually handled differently based on exact needs, 
        // but sticking to local saving for updates to avoid messing up the scope.
        final employee = Employee(
          id: existingId,
          name: name.trim(),
          companyId: companyId,
          createdAt: DateTime.now(),
        );
        await _localRepo.saveEmployee(employee);
      }

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
  return EmployeeFormNotifier(repo, supabase);
});
