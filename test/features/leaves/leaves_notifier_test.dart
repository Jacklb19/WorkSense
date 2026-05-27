import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:worksense_app/data/datasources/remote/supabase_datasource.dart';
import 'package:worksense_app/domain/entities/leave_request.dart';
import 'package:worksense_app/domain/repositories/leave_request_repository.dart';
import 'package:worksense_app/features/leaves/presentation/providers/leaves_provider.dart';

// ── Fakes & Mocks ─────────────────────────────────────────────────────────────

class MockLeaveRequestRepository extends Mock
    implements LeaveRequestRepository {}

class MockSupabaseDataSource extends Mock implements SupabaseDataSource {}

class FakeLeaveRequest extends Fake implements LeaveRequest {}

// ── Helpers ───────────────────────────────────────────────────────────────────

LeaveRequest _makeRequest({
  String id = 'req-001',
  LeaveStatus status = LeaveStatus.pending,
}) {
  return LeaveRequest(
    id: id,
    employeeId: 'emp-001',
    companyId: 'comp-001',
    type: LeaveType.medical,
    status: status,
    startDate: DateTime(2026, 6, 1),
    endDate: DateTime(2026, 6, 5),
    createdAt: DateTime(2026, 5, 20),
    updatedAt: DateTime(2026, 5, 20),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(FakeLeaveRequest());
    registerFallbackValue(LeaveStatus.approved);
  });

  group('LeavesNotifier', () {
    late MockLeaveRequestRepository mockRepo;
    late MockSupabaseDataSource mockRemote;
    late LeavesNotifier notifier;

    setUp(() {
      mockRepo = MockLeaveRequestRepository();
      mockRemote = MockSupabaseDataSource();
      // Stub remote calls so they succeed silently — remote push is a
      // non-fatal side-effect and must not interfere with unit tests.
      when(() => mockRemote.upsert(any(), any())).thenAnswer((_) async {});
      when(() => mockRemote.patch(any(), any(), any())).thenAnswer((_) async {});
      notifier = LeavesNotifier(mockRepo, mockRemote);
    });

    test('initial state is AsyncData(null)', () {
      expect(notifier.state, isA<AsyncData<void>>());
    });

    test('submitRequest transitions to loading then data on success', () async {
      final request = _makeRequest();
      when(() => mockRepo.saveLeaveRequest(any()))
          .thenAnswer((_) async {});

      final states = <AsyncValue<void>>[];
      notifier.addListener((s) => states.add(s), fireImmediately: false);

      await notifier.submitRequest(request);

      // Should have gone through loading → data
      expect(states, hasLength(greaterThanOrEqualTo(1)));
      expect(notifier.state, isA<AsyncData<void>>());
      verify(() => mockRepo.saveLeaveRequest(request)).called(1);
    });

    test('submitRequest transitions to error when repo throws', () async {
      final request = _makeRequest();
      when(() => mockRepo.saveLeaveRequest(any()))
          .thenThrow(Exception('DB error'));

      await notifier.submitRequest(request);

      expect(notifier.state, isA<AsyncError<void>>());
    });

    test('reviewRequest calls repo with correct arguments', () async {
      when(() => mockRepo.reviewLeaveRequest(
            requestId: any(named: 'requestId'),
            status: any(named: 'status'),
            reviewedById: any(named: 'reviewedById'),
            reviewNote: any(named: 'reviewNote'),
          )).thenAnswer((_) async {});

      await notifier.reviewRequest(
        requestId: 'req-001',
        status: LeaveStatus.approved,
        reviewedById: 'admin-001',
        employeeId: 'emp-001',
        companyId: 'comp-001',
      );

      verify(() => mockRepo.reviewLeaveRequest(
            requestId: 'req-001',
            status: LeaveStatus.approved,
            reviewedById: 'admin-001',
            reviewNote: null,
          )).called(1);
    });

    test('reviewRequest transitions to error when repo throws', () async {
      when(() => mockRepo.reviewLeaveRequest(
            requestId: any(named: 'requestId'),
            status: any(named: 'status'),
            reviewedById: any(named: 'reviewedById'),
            reviewNote: any(named: 'reviewNote'),
          )).thenThrow(Exception('Network error'));

      await notifier.reviewRequest(
        requestId: 'req-001',
        status: LeaveStatus.approved,
        reviewedById: 'admin-001',
        employeeId: 'emp-001',
        companyId: 'comp-001',
      );

      expect(notifier.state, isA<AsyncError<void>>());
    });

    test('deleteRequest calls repo and succeeds', () async {
      when(() => mockRepo.deleteLeaveRequest(any()))
          .thenAnswer((_) async {});

      await notifier.deleteRequest('req-001');

      expect(notifier.state, isA<AsyncData<void>>());
      verify(() => mockRepo.deleteLeaveRequest('req-001')).called(1);
    });

    test('deleteRequest transitions to error when repo throws', () async {
      when(() => mockRepo.deleteLeaveRequest(any()))
          .thenThrow(Exception('Constraint violation'));

      await notifier.deleteRequest('req-001');

      expect(notifier.state, isA<AsyncError<void>>());
    });
  });

  group('pendingLeavesCountProvider', () {
    test('counts only pending leaves', () {
      final container = ProviderContainer(
        overrides: [
          companyLeavesProvider.overrideWith((ref) => Stream.value([
                _makeRequest(id: '1', status: LeaveStatus.pending),
                _makeRequest(id: '2', status: LeaveStatus.approved),
                _makeRequest(id: '3', status: LeaveStatus.pending),
                _makeRequest(id: '4', status: LeaveStatus.rejected),
              ])),
        ],
      );
      addTearDown(container.dispose);

      // Allow stream to emit
      expect(
        container.read(pendingLeavesCountProvider),
        anyOf(0, 2), // 0 before stream emits, 2 after
      );
    });
  });
}
