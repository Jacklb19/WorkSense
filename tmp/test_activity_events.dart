import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/core/secrets/supabase_secrets.dart'; // Asumiendo que existe o inicializo

void main() async {
  // Inicializamos supabase para el test
  await Supabase.initialize(
    url: SupabaseSecrets.supabaseUrl,
    anonKey: SupabaseSecrets.supabaseAnonKey,
  );
  
  final client = Supabase.instance.client;
  
  print('--- PROBANDO ACTIVITY EVENTS ---');
  try {
    final response = await client.from('activity_events').select().limit(5);
    print('Eventos encontrados: ${response.length}');
    for (var row in response) {
      print(row);
    }
  } catch (e) {
    print('Error: $e');
  }
}
