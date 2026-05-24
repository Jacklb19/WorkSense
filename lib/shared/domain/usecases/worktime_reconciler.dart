import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';

class WorktimeReconciler {
  WorktimeReconciler(this._db);

  final AppDatabase _db;

  Future<List<Map<String, dynamic>>> buildDailySummaryPayloads() async {
    final logs = await _db.watchAttendanceLogs().first;
    final grouped = <String, List<AttendanceLogData>>{};
    for (final log in logs) {
      grouped.putIfAbsent('${log.employeeId}_${log.shiftDate.toIso8601String()}', () => []).add(log);
    }

    final payloads = <Map<String, dynamic>>[];
    for (final entry in grouped.entries) {
      final dayLogs = entry.value..sort((a, b) => a.clockInTime.compareTo(b.clockInTime));
      if (dayLogs.isEmpty) continue;

      final first = dayLogs.first;
      final employee = await _db.getEmployeeRecordById(first.employeeId);
      final shift = employee?.shiftId != null ? await _db.getShiftById(employee!.shiftId!) : null;
      final dayStart = DateTime(first.shiftDate.year, first.shiftDate.month, first.shiftDate.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final activities = await _db.getActivityEntriesForEmployeeDay(first.employeeId, dayStart, dayEnd);

      final anomalies = <String>[];
      int workedMinutes = 0;
      for (final log in dayLogs) {
        if (log.clockOutTime == null) {
          anomalies.add('open_session');
          continue;
        }
        workedMinutes += log.clockOutTime!
            .difference(log.clockInTime)
            .inMinutes
            .clamp(0, 24 * 60);
      }

      if (dayLogs.length > 4) {
        anomalies.add('too_many_segments');
      }
      if (activities.where((e) => e.state == ActivityState.ausente.name).length >= 3) {
        anomalies.add('repeated_absence_events');
      }

      final expectedMinutes = shift == null ? 0 : _expectedMinutes(shift);
      final breakMinutes = shift == null ? 0 : _breakMinutes(shift);
      final absenceMinutes = expectedMinutes > workedMinutes ? expectedMinutes - workedMinutes : 0;
      final lateMinutes = shift == null ? 0 : _lateMinutes(dayLogs.first.clockInTime, shift);
      final extraMinutes = workedMinutes > expectedMinutes ? workedMinutes - expectedMinutes : 0;

      final payload = {
        'id': '${first.employeeId}_${dayStart.toIso8601String()}',
        'employee_id': first.employeeId,
        'company_id': first.companyId,
        'work_date': dayStart.toIso8601String(),
        'shift_id': employee?.shiftId,
        'expected_minutes': expectedMinutes,
        'worked_minutes': workedMinutes,
        'break_minutes': breakMinutes,
        'absence_minutes': absenceMinutes,
        'late_minutes': lateMinutes,
        'extra_minutes': extraMinutes,
        'session_count': dayLogs.length,
        'anomalies_json': jsonEncode(anomalies),
        'source_version': 1,
        'updated_at': DateTime.now().toIso8601String(),
      };
      // Si el payload ya fue syncado exitosamente, no lo regeneramos
      final existingRows = await _db.customSelect(
        'SELECT synced FROM daily_work_summaries WHERE id = ?',
        variables: [Variable<String>(payload['id'] as String)],
      ).get();
      final alreadySynced = existingRows.isNotEmpty && existingRows.first.read<int>('synced') == 1;

      if (alreadySynced) {
        // Saltar — ya fue enviado a Supabase exitosamente
        continue;
      }

      await _db.upsertDailySummaryPayload(
        payload['id'] as String,
        jsonEncode(payload),
        updatedAt: DateTime.now(),
        synced: false,
      );
      payloads.add(payload);
    }
    return payloads;
  }

  Future<List<Map<String, dynamic>>> buildActivityRollupPayloads({
    Duration window = const Duration(minutes: 30),
  }) async {
    final events = await _db.getPendingSyncEntries();
    final grouped = <String, List<ActivityEntry>>{};

    for (final event in events) {
      if (event.employeeId == null || event.companyId == null) continue;
      final start = _bucketStart(event.timestamp, window);
      final key = '${event.employeeId}_${event.workstationId}_${start.toIso8601String()}';
      grouped.putIfAbsent(key, () => []).add(event);
    }

    final payloads = <Map<String, dynamic>>[];
    for (final entry in grouped.entries) {
      final items = entry.value..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final first = items.first;
      final windowStart = _bucketStart(first.timestamp, window);
      final windowEnd = windowStart.add(window);
      int workingMinutes = 0;
      int distractedMinutes = 0;
      int absentMinutes = 0;
      int unknownMinutes = 0;
      double totalConfidence = 0.0;

      for (final item in items) {
        totalConfidence += item.confidence;
        switch (_stateFromName(item.state)) {
          case ActivityState.trabajando:
            workingMinutes++;
            break;
          case ActivityState.distraido:
          case ActivityState.fatiga:
          case ActivityState.inactivo:
            distractedMinutes++;
            break;
          case ActivityState.ausente:
          case ActivityState.fueraDelArea:
            absentMinutes++;
            break;
          case ActivityState.noIdentificado:
            unknownMinutes++;
            break;
        }
      }

      final payload = {
        'id': entry.key,
        'employee_id': first.employeeId,
        'company_id': first.companyId,
        'workstation_id': first.workstationId,
        'window_start': windowStart.toIso8601String(),
        'window_end': windowEnd.toIso8601String(),
        'working_minutes': workingMinutes,
        'distracted_minutes': distractedMinutes,
        'absent_minutes': absentMinutes,
        'unknown_minutes': unknownMinutes,
        'avg_confidence': items.isEmpty ? 0.0 : totalConfidence / items.length,
        'event_count': items.length,
      };
      await _db.upsertActivityRollupPayload(
        payload['id'] as String,
        jsonEncode(payload),
        updatedAt: DateTime.now(),
      );
      payloads.add(payload);
    }
    return payloads;
  }

  int _expectedMinutes(ShiftRecordData shift) {
    final total = _timeToMinutes(shift.endHour, shift.endMinute) -
        _timeToMinutes(shift.startHour, shift.startMinute);
    return total - _breakMinutes(shift);
  }

  int _breakMinutes(ShiftRecordData shift) {
    if (shift.breakStartHour == null ||
        shift.breakStartMinute == null ||
        shift.breakEndHour == null ||
        shift.breakEndMinute == null) {
      return 0;
    }
    return _timeToMinutes(shift.breakEndHour!, shift.breakEndMinute!) -
        _timeToMinutes(shift.breakStartHour!, shift.breakStartMinute!);
  }

  int _lateMinutes(DateTime clockIn, ShiftRecordData shift) {
    final start = DateTime(
      clockIn.year,
      clockIn.month,
      clockIn.day,
      shift.startHour,
      shift.startMinute,
    );
    final diff = clockIn.difference(start).inMinutes;
    return diff > 0 ? diff : 0;
  }

  int _timeToMinutes(int hour, int minute) => hour * 60 + minute;

  DateTime _bucketStart(DateTime timestamp, Duration window) {
    final minutes = timestamp.hour * 60 + timestamp.minute;
    final bucketMinutes = (minutes ~/ window.inMinutes) * window.inMinutes;
    return DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
      bucketMinutes ~/ 60,
      bucketMinutes % 60,
    );
  }

  ActivityState _stateFromName(String name) {
    return ActivityState.values.firstWhere(
      (state) => state.name == name,
      orElse: () => ActivityState.noIdentificado,
    );
  }
}
