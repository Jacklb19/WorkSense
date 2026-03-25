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

  // MÃ©todos especÃficos (usan el genÃ©rico internamente)
  Future<void> insertEmployee(Map<String, dynamic> data) =>
      upsert('employees', data);

  Future<void> insertWorkstation(Map<String, dynamic> data) =>
      upsert('workstations', data);

  Future<void> insertCompany(Map<String, dynamic> data) =>
      upsert('companies', data);

  Future<void> insertActivityEvent(Map<String, dynamic> data) =>
      upsert('activity_events', data);

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
