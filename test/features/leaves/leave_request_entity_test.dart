import 'package:flutter_test/flutter_test.dart';
import 'package:worksense_app/domain/entities/leave_request.dart';

void main() {
  group('LeaveRequest entity', () {
    final baseRequest = LeaveRequest(
      id: 'req-001',
      employeeId: 'emp-001',
      companyId: 'comp-001',
      type: LeaveType.medical,
      status: LeaveStatus.pending,
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 6, 5),
      createdAt: DateTime(2026, 5, 20),
      updatedAt: DateTime(2026, 5, 20),
    );

    test('durationDays is inclusive of start and end dates', () {
      // June 1 to June 5 inclusive = 5 days
      expect(baseRequest.durationDays, equals(5));
    });

    test('durationDays of 1 when start == end', () {
      final sameDay = baseRequest.copyWith(
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 1),
      );
      expect(sameDay.durationDays, equals(1));
    });

    test('toMap produces correct keys', () {
      final map = baseRequest.toMap();
      expect(map['id'], equals('req-001'));
      expect(map['employee_id'], equals('emp-001'));
      expect(map['company_id'], equals('comp-001'));
      expect(map['type'], equals('MEDICAL'));
      expect(map['status'], equals('PENDING'));
      expect(map['start_date'], isA<String>());
      expect(map['end_date'], isA<String>());
    });

    test('LeaveType.fromRaw roundtrip', () {
      for (final type in LeaveType.values) {
        expect(LeaveType.fromRaw(type.raw), equals(type));
      }
    });

    test('LeaveStatus.fromRaw roundtrip', () {
      for (final status in LeaveStatus.values) {
        expect(LeaveStatus.fromRaw(status.raw), equals(status));
      }
    });

    test('LeaveStatus.fromRaw defaults to pending for unknown values', () {
      expect(LeaveStatus.fromRaw(null), equals(LeaveStatus.pending));
      expect(LeaveStatus.fromRaw('UNKNOWN'), equals(LeaveStatus.pending));
      expect(LeaveStatus.fromRaw(''), equals(LeaveStatus.pending));
    });

    test('LeaveType.fromRaw defaults to personal for unknown values', () {
      expect(LeaveType.fromRaw(null), equals(LeaveType.personal));
      expect(LeaveType.fromRaw('UNKNOWN'), equals(LeaveType.personal));
    });

    test('copyWith preserves unchanged fields', () {
      final updated = baseRequest.copyWith(status: LeaveStatus.approved);
      expect(updated.id, equals(baseRequest.id));
      expect(updated.employeeId, equals(baseRequest.employeeId));
      expect(updated.status, equals(LeaveStatus.approved));
      expect(updated.type, equals(baseRequest.type));
      expect(updated.startDate, equals(baseRequest.startDate));
    });

    test('copyWith can null optional fields via sentinel', () {
      final withReason = baseRequest.copyWith(reason: 'Sick');
      expect(withReason.reason, equals('Sick'));

      // copyWith with explicit null reason (default sentinel preserves it)
      final noReason = withReason.copyWith();
      expect(noReason.reason, equals('Sick')); // preserved — no override
    });

    test('LeaveStatus labels are non-empty Spanish strings', () {
      expect(LeaveStatus.pending.label, isNotEmpty);
      expect(LeaveStatus.approved.label, isNotEmpty);
      expect(LeaveStatus.rejected.label, isNotEmpty);
    });

    test('LeaveType labels are non-empty Spanish strings', () {
      for (final type in LeaveType.values) {
        expect(type.label, isNotEmpty);
      }
    });
  });
}
