import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worksense_app/data/datasources/remote/supabase_datasource.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}

void main() {
  late SupabaseDatasource datasource;
  late MockSupabaseClient mockSupabase;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    datasource = SupabaseDatasource(mockSupabase);
  });

  group('SupabaseDatasource', () {
    test('Ping calls RPC check_connection and returns true on success', () async {
      when(() => mockSupabase.rpc('check_connection')).thenAnswer((_) async => true);

      final result = await datasource.ping();

      expect(result, isTrue);
      verify(() => mockSupabase.rpc('check_connection')).called(1);
    });

    test('Ping handles failures gracefully', () async {
      when(() => mockSupabase.rpc('check_connection')).thenThrow(const PostgrestException(message: 'Error'));

      final result = await datasource.ping();

      expect(result, isFalse);
    });
  });
}
