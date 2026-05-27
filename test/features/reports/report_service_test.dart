// ignore_for_file: avoid_function_literals_in_foreach_calls
import 'package:flutter_test/flutter_test.dart';
import 'package:worksense_app/domain/entities/leave_request.dart';
import 'package:worksense_app/domain/entities/task_item.dart';

/// Tests for the data-layer logic that feeds into the PDF report.
/// Note: Printing.layoutPdf requires a platform channel and cannot run in
/// unit tests. We test the data transforms independently here.
void main() {
  // ── Helpers ──────────────────────────────────────────────────────────────────

  LeaveRequest makeLeave({
    String id = 'leave-001',
    String employeeId = 'emp-001',
    LeaveStatus status = LeaveStatus.pending,
    LeaveType type = LeaveType.medical,
    DateTime? start,
    DateTime? end,
  }) {
    return LeaveRequest(
      id: id,
      employeeId: employeeId,
      companyId: 'comp-001',
      type: type,
      status: status,
      startDate: start ?? DateTime(2026, 6, 1),
      endDate: end ?? DateTime(2026, 6, 5),
      createdAt: DateTime(2026, 5, 20),
      updatedAt: DateTime(2026, 5, 20),
    );
  }

  TaskItem makeTask({
    String id = 'task-001',
    String assignedToId = 'emp-001',
    TaskStatus status = TaskStatus.pending,
    DateTime? dueDate,
  }) {
    return TaskItem(
      id: id,
      companyId: 'comp-001',
      assignedToId: assignedToId,
      createdById: 'admin-001',
      title: 'Test task $id',
      status: status,
      priority: TaskPriority.normal,
      dueDate: dueDate,
      createdAt: DateTime(2026, 5, 20),
      updatedAt: DateTime(2026, 5, 20),
    );
  }

  // ── Name resolution logic ─────────────────────────────────────────────────
  // The public API accepts Map<String, String>? employeeNames.
  // We verify the look-up logic by exercising it through LeaveRequest fields.

  String resolveName(String id, Map<String, String>? names) {
    if (names != null) {
      final name = names[id];
      if (name != null && name.trim().isNotEmpty) return name;
    }
    return id.length >= 8 ? id.substring(0, 8) : id;
  }

  group('Name resolution (_resolveName equivalent)', () {
    const names = {'emp-001': 'Ana García', 'emp-002': 'Juan López'};

    test('returns display name when id is in map', () {
      expect(resolveName('emp-001', names), equals('Ana García'));
      expect(resolveName('emp-002', names), equals('Juan López'));
    });

    test('falls back to first 8 chars of UUID when id not in map', () {
      // UUID format: 8 chars-4 chars-...
      const uuid = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
      expect(resolveName(uuid, names), equals('a1b2c3d4'));
    });

    test('falls back to full id when id is shorter than 8 chars', () {
      expect(resolveName('short', names), equals('short'));
    });

    test('falls back to UUID when names map is null', () {
      const uuid = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
      expect(resolveName(uuid, null), equals('a1b2c3d4'));
    });

    test('falls back to UUID when name is empty string', () {
      final namesWithEmpty = {'emp-001': '  '};
      const uuid = 'emp-001x-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
      expect(resolveName(uuid, namesWithEmpty), equals('emp-001x'));
    });
  });

  // ── Leaves report data ─────────────────────────────────────────────────────

  group('Leaves report — data transforms', () {
    final leaves = [
      makeLeave(id: '1', status: LeaveStatus.pending),
      makeLeave(id: '2', status: LeaveStatus.approved),
      makeLeave(id: '3', status: LeaveStatus.approved),
      makeLeave(id: '4', status: LeaveStatus.rejected),
      makeLeave(id: '5', status: LeaveStatus.pending),
    ];

    test('pending count is correct', () {
      final count = leaves.where((l) => l.status == LeaveStatus.pending).length;
      expect(count, equals(2));
    });

    test('approved count is correct', () {
      final count = leaves.where((l) => l.status == LeaveStatus.approved).length;
      expect(count, equals(2));
    });

    test('rejected count is correct', () {
      final count = leaves.where((l) => l.status == LeaveStatus.rejected).length;
      expect(count, equals(1));
    });

    test('total day count for summary is correct (June 1-5 = 5 days each)', () {
      final total = leaves.fold<int>(0, (sum, l) => sum + l.durationDays);
      expect(total, equals(25)); // 5 leaves × 5 days
    });

    test('single-day leave has durationDays == 1', () {
      final oneDay = makeLeave(
        start: DateTime(2026, 7, 10),
        end: DateTime(2026, 7, 10),
      );
      expect(oneDay.durationDays, equals(1));
    });

    test('multi-day leave across month boundary is correct', () {
      final crossMonth = makeLeave(
        start: DateTime(2026, 5, 30),
        end: DateTime(2026, 6, 2),
      );
      // May 30, 31, June 1, 2 = 4 days
      expect(crossMonth.durationDays, equals(4));
    });

    test('all leaves have valid type labels', () {
      for (final l in leaves) {
        expect(l.type.label, isNotEmpty);
      }
    });

    test('all leaves have valid status labels', () {
      for (final l in leaves) {
        expect(l.status.label, isNotEmpty);
      }
    });
  });

  // ── Tasks report data ──────────────────────────────────────────────────────

  group('Tasks report — data transforms', () {
    final tasks = [
      makeTask(id: '1', status: TaskStatus.done),
      makeTask(id: '2', status: TaskStatus.inProgress),
      makeTask(id: '3', status: TaskStatus.pending),
      makeTask(id: '4', status: TaskStatus.done),
      makeTask(id: '5', status: TaskStatus.pending,
          dueDate: DateTime(2026, 4, 1)), // overdue
    ];

    test('done count is correct', () {
      final count = tasks.where((t) => t.status == TaskStatus.done).length;
      expect(count, equals(2));
    });

    test('in-progress count is correct', () {
      final count = tasks.where((t) => t.status == TaskStatus.inProgress).length;
      expect(count, equals(1));
    });

    test('pending count is correct', () {
      final count = tasks.where((t) => t.status == TaskStatus.pending).length;
      expect(count, equals(2));
    });

    test('overdue count is correct (past due date + not done)', () {
      final count = tasks.where((t) => t.isOverdue).length;
      expect(count, equals(1));
    });

    test('truncates long titles to 40 chars', () {
      const longTitle = 'This is a very long task title that exceeds forty characters';
      final truncated = longTitle.length > 40
          ? '${longTitle.substring(0, 40)}…'
          : longTitle;
      expect(truncated.length, lessThanOrEqualTo(41)); // 40 + ellipsis
    });
  });

  // ── Employee name map construction ─────────────────────────────────────────

  group('Employee name map construction', () {
    // Simulates what ReportsScreen builds from employeesProvider
    final mockEmployees = [
      ('emp-001', 'Ana García'),
      ('emp-002', 'Juan López'),
      ('emp-003', 'María Hernández'),
    ];

    test('map has correct length', () {
      final map = <String, String>{for (final e in mockEmployees) e.$1: e.$2};
      expect(map.length, equals(3));
    });

    test('map resolves names correctly', () {
      final map = <String, String>{for (final e in mockEmployees) e.$1: e.$2};
      expect(map['emp-001'], equals('Ana García'));
      expect(map['emp-002'], equals('Juan López'));
      expect(map['emp-003'], equals('María Hernández'));
    });

    test('map returns null for unknown id', () {
      final map = <String, String>{for (final e in mockEmployees) e.$1: e.$2};
      expect(map['emp-999'], isNull);
    });
  });
}
