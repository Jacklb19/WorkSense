import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worksense_app/core/constants/app_constants.dart';
import 'package:worksense_app/domain/entities/app_role.dart';

class SupabaseDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  /// MÃ©todo genÃ©rico â€” el nÃºcleo del Outbox Pattern
  Future<void> upsert(String table, Map<String, dynamic> data) async {
    try {
      await _client.from(table).upsert(data);
    } on PostgrestException catch (e) {
      throw SyncException(
        'Error upserting en $table: ${e.message} (code: ${e.code})',
      );
    } catch (e) {
      throw SyncException('Error inesperado en $table: $e');
    }
  }

  Future<void> upsertBatch(String table, List<Map<String, dynamic>> dataList) async {
    if (dataList.isEmpty) return;
    try {
      await _client.from(table).upsert(dataList);
    } on PostgrestException catch (e) {
      throw SyncException(
        'Error upserting batch en $table: ${e.message} (code: ${e.code})',
      );
    } catch (e) {
      throw SyncException('Error inesperado batch en $table: $e');
    }
  }

  Future<void> delete(String table, String id) async {
    try {
      await _client.from(table).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw SyncException('Error eliminando en $table: ${e.message}');
    }
  }

  Future<void> patch(String table, String id, Map<String, dynamic> data) async {
    try {
      await _client.from(table).update(data).eq('id', id);
    } on PostgrestException catch (e) {
      throw SyncException(
        'Error parcheando en $table: ${e.message} (code: ${e.code})',
      );
    } catch (e) {
      throw SyncException('Error inesperado en $table patch: $e');
    }
  }

  // MÃ©todos especÃficos (usan el genÃ©rico internamente)
  Future<void> insertEmployee(Map<String, dynamic> data) =>
      upsert('employees', data);

  Future<void> insertWorkstation(Map<String, dynamic> data) =>
      upsert('workstations', data);

  Future<void> insertCompany(Map<String, dynamic> data) =>
      upsert('companies', data);

  Future<void> insertActivityEvent(Map<String, dynamic> data) =>
      upsert('activity_events', data);

  /// Fetches activity events from Supabase for a specific employee within a date range.
  Future<List<Map<String, dynamic>>> fetchActivityEventsForEmployee(
    String employeeId, {
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final response = await _client
          .from('activity_events')
          .select()
          .eq('employee_id', employeeId)
          .gte('timestamp', from.toUtc().toIso8601String())
          .lte('timestamp', to.toUtc().toIso8601String())
          .order('timestamp', ascending: true)
          .limit(2000);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw SyncException('Error obteniendo activity_events: $e');
    }
  }

  /// Fetches all activity events from Supabase within a date range (for all employees).
  Future<List<Map<String, dynamic>>> fetchActivityEventsByDateRange({
    required DateTime from,
    required DateTime to,
    String? companyId,
  }) async {
    try {
      var query = _client
          .from('activity_events')
          .select()
          .not('employee_id', 'is', null);
      
      if (companyId != null && companyId != AppConstants.defaultCompanyId) {
        query = query.eq('company_id', companyId);
      }

      final response = await query
          .gte('timestamp', from.toUtc().toIso8601String())
          .lte('timestamp', to.toUtc().toIso8601String())
          .order('timestamp', ascending: true)
          .limit(5000);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw SyncException('Error obteniendo activity_events: $e');
    }
  }

  /// Fetches attendance logs from Supabase for a specific employee within a date range.
  Future<List<Map<String, dynamic>>> fetchAttendanceLogsForEmployee(
    String employeeId, {
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final response = await _client
          .from('attendance_logs')
          .select()
          .eq('employee_id', employeeId)
          .gte('shift_date', from.toUtc().toIso8601String().split('T').first)
          .lte('shift_date', to.toUtc().toIso8601String().split('T').first)
          .order('clock_in_time', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw SyncException('Error obteniendo attendance_logs: $e');
    }
  }

  // Authentication & Admin Methods
  Future<Map<String, dynamic>> createEmployeeWithAuth(Map<String, dynamic> data) async {
    try {
      final response = await _client.functions.invoke(
        'create-employee',
        body: data,
      );
      if (response.status != 200) {
        throw SyncException('Error en Edge Function: ${response.data}');
      }
      // Edge function will return { "id": "uuid", "message": "..." } on success
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw SyncException('Error creando empleado con Auth: $e');
    }
  }

  Future<Map<String, dynamic>> updateEmployeeWithAuth(Map<String, dynamic> data) async {
    try {
      final response = await _client.functions.invoke(
        'update-employee',
        body: data,
      );
      if (response.status != 200) {
        throw SyncException('Error en Edge Function: ${response.data}');
      }
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw SyncException('Error actualizando empleado con Auth: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchCurrentEmployee() async {
    final userId = currentUserId;
    final user = _client.auth.currentUser;
    if (userId == null || user == null) return null;
    try {
      final response = await _client
          .from('employees')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      // Auto-repair: if employee record doesn't exist but user is authenticated,
      // create a minimal record using JWT metadata
      if (response == null) {
        final meta = user.appMetadata;
        final userMeta = user.userMetadata;
        final companyId = _getMetadataKey(meta, 'company_id') ?? _getMetadataKey(userMeta, 'company_id');
        final roleStr = _getMetadataKey(meta, 'role') ?? _getMetadataKey(userMeta, 'role') ?? 'EMPLOYEE';
        
        final newRecord = {
          'id': userId,
          'name': user.userMetadata?['name']?.toString().split(' ').first ?? 'Usuario',
          'last_name': user.userMetadata?['name']?.toString().split(' ').skip(1).join(' ') ?? '',
          'email': user.email ?? '',
          'role': roleStr.toUpperCase(),
          'company_id': companyId ?? AppConstants.defaultCompanyId,
        };
        
        try {
          final insertResult = await _client.from('employees').insert(newRecord).select().maybeSingle();
          return insertResult;
        } catch (_) {
          // If insert fails (e.g., no permission), return null
          return null;
        }
      }
      
      return response;
    } catch (e) {
      throw SyncException('Error obteniendo empleado actual: $e');
    }
  }

String? _getMetadataKey(Map<String, dynamic>? metadata, String key) {
    if (metadata == null) return null;
    final lowerKey = key.toLowerCase();
    for (final k in metadata.keys) {
      final lk = k.toLowerCase();
      if (lk == lowerKey) {
        return metadata[k]?.toString();
      }
    }
    return null;
  }

String? get currentCompanyId {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final meta = user.appMetadata;
    final userMeta = user.userMetadata;
    final companyId =
        _getMetadataKey(meta, 'company_id') ??
        _getMetadataKey(userMeta, 'company_id');
    if (companyId == null || companyId.isEmpty || companyId == AppConstants.defaultCompanyId) {
      return null;
    }
    return companyId;
  }

  AppRole get currentRole {
    final user = _client.auth.currentUser;
    if (user == null) return AppRole.employee;
    final meta = user.appMetadata;
    final userMeta = user.userMetadata;
    return AppRoleX.fromRaw(
      _getMetadataKey(meta, 'role') ??
      _getMetadataKey(userMeta, 'role'),
    );
  }

  Future<List<Map<String, dynamic>>> fetchAllEmployees(String? companyId) async {
    try {
      var query = _client.from('employees').select();
      if (companyId != null && companyId != AppConstants.defaultCompanyId) {
        query = query.eq('company_id', companyId);
      }
      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw SyncException('Error obteniendo empleados: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllWorkstations(String? companyId) async {
    try {
      var query = _client.from('workstations').select();
      if (companyId != null && companyId != AppConstants.defaultCompanyId) {
        query = query.eq('company_id', companyId);
      }
      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw SyncException('Error obteniendo workstations: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllShifts(String? companyId) async {
    try {
      var query = _client.from('shifts').select();
      if (companyId != null && companyId != AppConstants.defaultCompanyId) {
        query = query.eq('company_id', companyId);
      }
      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw SyncException('Error obteniendo shifts: $e');
    }
  }

  // Test de conectividad aislado
  Future<bool> testConnection() async {
    try {
      await _client.from('employees').select('id').limit(1);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Getters para UI o procesos internos
  Stream<bool> get authStateStream =>
      _client.auth.onAuthStateChange
          .map((event) => event.session != null);

  String? get currentUserEmail => _client.auth.currentUser?.email;

  String? get currentUserId => _client.auth.currentUser?.id;

  bool get isSignedIn => _client.auth.currentSession != null;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

class SyncException implements Exception {
  final String message;
  SyncException(this.message);
  @override
  String toString() => 'SyncException: $message';
}
