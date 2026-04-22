import 'package:supabase_flutter/supabase_flutter.dart';

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
      
      if (companyId != null && companyId != 'default') {
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

  Future<Map<String, dynamic>?> fetchCurrentEmployee() async {
    final userId = currentUserId;
    if (userId == null) return null;
    try {
      final response = await _client
          .from('employees')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      throw SyncException('Error obteniendo empleado actual: $e');
    }
  }

  String? get currentCompanyId {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final meta = user.appMetadata ?? {};
    final userMeta = user.userMetadata ?? {};
    return (meta['company_id']?.toString() ?? userMeta['company_id']?.toString());
  }

  Future<List<Map<String, dynamic>>> fetchAllEmployees(String? companyId) async {
    try {
      var query = _client.from('employees').select();
      if (companyId != null && companyId != 'default') {
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
      if (companyId != null && companyId != 'default') {
        query = query.eq('company_id', companyId);
      }
      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw SyncException('Error obteniendo workstations: $e');
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
