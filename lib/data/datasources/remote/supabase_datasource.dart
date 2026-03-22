import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  // ── Activity Events ───────────────────────────────────────────────────────

  Future<void> insertActivityEvent(Map<String, dynamic> data) async {
    await _client.from('activity_events').insert(data);
  }

  Future<List<Map<String, dynamic>>> getActivityEvents({
    String? workstationId,
    int limit = 50,
  }) async {
    var query = _client
        .from('activity_events')
        .select()
        .order('timestamp', ascending: false)
        .limit(limit);

    if (workstationId != null) {
      query = _client
          .from('activity_events')
          .select()
          .eq('workstation_id', workstationId)
          .order('timestamp', ascending: false)
          .limit(limit);
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  // ── Workstations ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getWorkstations() async {
    final response = await _client.from('workstations').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> insertWorkstation(Map<String, dynamic> data) async {
    await _client.from('workstations').insert(data);
  }

  Future<void> updateWorkstation(
      String id, Map<String, dynamic> data) async {
    await _client.from('workstations').update(data).eq('id', id);
  }

  // ── Employees ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getEmployees() async {
    final response = await _client.from('employees').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> insertEmployee(Map<String, dynamic> data) async {
    await _client.from('employees').insert(data);
  }

  Future<void> updateEmployee(
      String id, Map<String, dynamic> data) async {
    await _client.from('employees').update(data).eq('id', id);
  }

  Future<void> deleteEmployee(String id) async {
    await _client.from('employees').delete().eq('id', id);
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

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
