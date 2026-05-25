import 'dart:convert';

class DailyWorkSummary {
  final String id;
  final String employeeId;
  final String companyId;
  final DateTime workDate;
  final String? shiftId;
  final int expectedMinutes;
  final int workedMinutes;
  final int breakMinutes;
  final int absenceMinutes;
  final int lateMinutes;
  final int extraMinutes;
  final int sessionCount;
  final List<String> anomalies;
  final int sourceVersion;
  final DateTime updatedAt;
  final bool synced;

  const DailyWorkSummary({
    required this.id,
    required this.employeeId,
    required this.companyId,
    required this.workDate,
    required this.shiftId,
    required this.expectedMinutes,
    required this.workedMinutes,
    required this.breakMinutes,
    required this.absenceMinutes,
    required this.lateMinutes,
    required this.extraMinutes,
    required this.sessionCount,
    required this.anomalies,
    required this.sourceVersion,
    required this.updatedAt,
    required this.synced,
  });

  bool get hasAnomalies => anomalies.isNotEmpty;
  double get completionRatio =>
      expectedMinutes <= 0 ? 0 : (workedMinutes / expectedMinutes).clamp(0, 1);

  factory DailyWorkSummary.fromStoredPayload({
    required Map<String, dynamic> payload,
    required DateTime updatedAt,
    required bool synced,
  }) {
    final anomaliesRaw = jsonDecode(payload['anomalies_json'] as String? ?? '[]');
    return DailyWorkSummary(
      id: payload['id'] as String,
      employeeId: payload['employee_id'] as String,
      companyId: payload['company_id'] as String? ?? '',
      workDate: DateTime.parse(payload['work_date'] as String),
      shiftId: payload['shift_id'] as String?,
      expectedMinutes: payload['expected_minutes'] as int? ?? 0,
      workedMinutes: payload['worked_minutes'] as int? ?? 0,
      breakMinutes: payload['break_minutes'] as int? ?? 0,
      absenceMinutes: payload['absence_minutes'] as int? ?? 0,
      lateMinutes: payload['late_minutes'] as int? ?? 0,
      extraMinutes: payload['extra_minutes'] as int? ?? 0,
      sessionCount: payload['session_count'] as int? ?? 0,
      anomalies: (anomaliesRaw as List<dynamic>).map((e) => e.toString()).toList(),
      sourceVersion: payload['source_version'] as int? ?? 1,
      updatedAt: updatedAt,
      synced: synced,
    );
  }
}
