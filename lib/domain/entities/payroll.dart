import 'package:flutter/material.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum PayrollStatus {
  draft('draft', 'Borrador', Color(0xFF94A3B8)),
  approved('approved', 'Aprobado', Color(0xFF10B981)),
  paid('paid', 'Pagado', Color(0xFF4F8EF7));

  final String value;
  final String label;
  final Color color;
  const PayrollStatus(this.value, this.label, this.color);

  static PayrollStatus fromString(String? s) => switch (s) {
        'approved' => approved,
        'paid' => paid,
        _ => draft,
      };
}

// ── PayrollConfig ─────────────────────────────────────────────────────────────

class PayrollConfig {
  final String id;
  final String employeeId;
  final String companyId;
  final double hourlyRate;
  final String currency;
  final DateTime updatedAt;

  const PayrollConfig({
    required this.id,
    required this.employeeId,
    required this.companyId,
    required this.hourlyRate,
    this.currency = 'COP',
    required this.updatedAt,
  });

  factory PayrollConfig.fromMap(Map<String, dynamic> m) => PayrollConfig(
        id: m['id'] as String,
        employeeId: m['employee_id'] as String,
        companyId: m['company_id'] as String,
        hourlyRate: (m['hourly_rate'] as num).toDouble(),
        currency: m['currency'] as String? ?? 'COP',
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'employee_id': employeeId,
        'company_id': companyId,
        'hourly_rate': hourlyRate,
        'currency': currency,
        'updated_at': updatedAt.toIso8601String(),
      };

  PayrollConfig copyWith({double? hourlyRate, String? currency}) => PayrollConfig(
        id: id,
        employeeId: employeeId,
        companyId: companyId,
        hourlyRate: hourlyRate ?? this.hourlyRate,
        currency: currency ?? this.currency,
        updatedAt: DateTime.now(),
      );
}

// ── PayrollPeriod ─────────────────────────────────────────────────────────────

class PayrollPeriod {
  final String id;
  final String companyId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final PayrollStatus status;
  final double totalGross;
  final int employeeCount;
  final DateTime createdAt;
  final String createdBy;

  const PayrollPeriod({
    required this.id,
    required this.companyId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.status = PayrollStatus.draft,
    this.totalGross = 0,
    this.employeeCount = 0,
    required this.createdAt,
    required this.createdBy,
  });

  factory PayrollPeriod.fromMap(Map<String, dynamic> m) => PayrollPeriod(
        id: m['id'] as String,
        companyId: m['company_id'] as String,
        name: m['name'] as String,
        startDate: DateTime.parse(m['start_date'] as String),
        endDate: DateTime.parse(m['end_date'] as String),
        status: PayrollStatus.fromString(m['status'] as String?),
        totalGross: (m['total_gross'] as num?)?.toDouble() ?? 0,
        employeeCount: (m['employee_count'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(m['created_at'] as String),
        createdBy: m['created_by'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'name': name,
        'start_date': startDate.toIso8601String().split('T').first,
        'end_date': endDate.toIso8601String().split('T').first,
        'status': status.value,
        'total_gross': totalGross,
        'employee_count': employeeCount,
        'created_at': createdAt.toIso8601String(),
        'created_by': createdBy,
      };
}

// ── PayrollEntry ──────────────────────────────────────────────────────────────

class PayrollEntry {
  final String id;
  final String periodId;
  final String employeeId;
  final String companyId;
  final double hoursWorked;
  final double hourlyRate;
  final double grossPay;
  final double deductions;
  final double netPay;
  final String currency;

  const PayrollEntry({
    required this.id,
    required this.periodId,
    required this.employeeId,
    required this.companyId,
    required this.hoursWorked,
    required this.hourlyRate,
    required this.grossPay,
    this.deductions = 0,
    required this.netPay,
    this.currency = 'COP',
  });

  factory PayrollEntry.fromMap(Map<String, dynamic> m) => PayrollEntry(
        id: m['id'] as String,
        periodId: m['period_id'] as String,
        employeeId: m['employee_id'] as String,
        companyId: m['company_id'] as String,
        hoursWorked: (m['hours_worked'] as num).toDouble(),
        hourlyRate: (m['hourly_rate'] as num).toDouble(),
        grossPay: (m['gross_pay'] as num).toDouble(),
        deductions: (m['deductions'] as num?)?.toDouble() ?? 0,
        netPay: (m['net_pay'] as num).toDouble(),
        currency: m['currency'] as String? ?? 'COP',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'period_id': periodId,
        'employee_id': employeeId,
        'company_id': companyId,
        'hours_worked': hoursWorked,
        'hourly_rate': hourlyRate,
        'gross_pay': grossPay,
        'deductions': deductions,
        'net_pay': netPay,
        'currency': currency,
      };
}
