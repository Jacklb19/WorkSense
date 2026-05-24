import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:worksense_app/core/routing/app_router.dart';

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  group('AppRouter Configuration Tests', () {
    test('Router provider creates a valid GoRouter instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      
      expect(router, isA<GoRouter>());
    });

    // To test redirect logic, we would mock the ref and state, but GoRouter redirect testing
    // is best done with pumpWidget in a Widget test or isolating the redirect function.
  });
}
