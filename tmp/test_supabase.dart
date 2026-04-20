import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Test rápido para verificar conexión a Supabase
Future<void> testSupabaseConnectivity() async {
  final client = Supabase.instance.client;
  final testId = const Uuid().v4();
  
  print('--- TEST SUPABASE START ---');
  try {
    // 1. Verificar sesión anónima (si aplica)
    print('Current User: ${client.auth.currentUser?.email ?? 'Anonymous'}');

    // 2. Intentar inserción directa en employees
    await client.from('employees').insert({
      'id': testId,
      'name': 'Test User ${DateTime.now().second}',
      'company_id': '00000000-0000-0000-0000-000000000000', // Asumir que existe una default
      'created_at': DateTime.now().toIso8601String(),
    });
    
    print('INSERT SUCCESS: Registro creado con ID $testId');

    // 3. Verificar lectura
    final response = await client.from('employees').select().eq('id', testId).single();
    print('SELECT SUCCESS: Leído registro: ${response['name']}');

    // 4. Limpiar (opcional)
    await client.from('employees').delete().eq('id', testId);
    print('DELETE SUCCESS: Registro temporal eliminado');
    
  } on PostgrestException catch (e) {
    print('POSTGREST ERROR: ${e.message} (Code: ${e.code})');
    if (e.code == '42501') {
      print('CONSEJO: Error de permisos. Verifica políticas RLS en Supabase.');
    }
  } catch (e) {
    print('UNEXPECTED ERROR: $e');
  }
  print('--- TEST SUPABASE END ---');
}
