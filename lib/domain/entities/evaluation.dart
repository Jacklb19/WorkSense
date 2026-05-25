import 'dart:convert';
import 'package:flutter/material.dart';

// ── EvaluationCriterion ───────────────────────────────────────────────────────

class EvaluationCriterion {
  final String name;
  final double maxScore;

  const EvaluationCriterion({required this.name, this.maxScore = 10});

  factory EvaluationCriterion.fromMap(Map<String, dynamic> m) =>
      EvaluationCriterion(
        name: m['name'] as String,
        maxScore: (m['max_score'] as num?)?.toDouble() ?? 10,
      );

  Map<String, dynamic> toMap() => {'name': name, 'max_score': maxScore};
}

// ── Default template ──────────────────────────────────────────────────────────

const defaultCriteria = [
  EvaluationCriterion(name: 'Puntualidad',         maxScore: 10),
  EvaluationCriterion(name: 'Productividad',        maxScore: 10),
  EvaluationCriterion(name: 'Actitud',              maxScore: 10),
  EvaluationCriterion(name: 'Trabajo en equipo',    maxScore: 10),
  EvaluationCriterion(name: 'Calidad del trabajo',  maxScore: 10),
];

// ── Evaluation ────────────────────────────────────────────────────────────────

class Evaluation {
  final String id;
  final String companyId;
  final String employeeId;
  final String reviewerId;
  final String period;
  final List<EvaluationCriterion> criteria;
  final Map<String, double> scores; // criterionName → score
  final double totalScore;
  final double maxScore;
  final String? notes;
  final DateTime createdAt;

  const Evaluation({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.reviewerId,
    required this.period,
    required this.criteria,
    required this.scores,
    required this.totalScore,
    required this.maxScore,
    this.notes,
    required this.createdAt,
  });

  // ── Derived ─────────────────────────────────────────────────────────────────

  double get percentage => maxScore > 0 ? (totalScore / maxScore) * 100 : 0;

  String get grade {
    if (percentage >= 90) return 'A';
    if (percentage >= 80) return 'B';
    if (percentage >= 70) return 'C';
    if (percentage >= 60) return 'D';
    return 'F';
  }

  Color get gradeColor {
    if (percentage >= 90) return const Color(0xFF10B981); // green
    if (percentage >= 80) return const Color(0xFF4F8EF7); // blue
    if (percentage >= 70) return const Color(0xFFF59E0B); // yellow
    if (percentage >= 60) return const Color(0xFFF97316); // orange
    return const Color(0xFFEF4444);                       // red
  }

  String get gradeLabel {
    if (percentage >= 90) return 'Excelente';
    if (percentage >= 80) return 'Bueno';
    if (percentage >= 70) return 'Aceptable';
    if (percentage >= 60) return 'Regular';
    return 'Deficiente';
  }

  // ── Serialization ────────────────────────────────────────────────────────────

  factory Evaluation.fromMap(Map<String, dynamic> m) {
    final rawScores  = m['scores'];
    final rawCrit    = m['criteria'];

    final scoresMap = ((rawScores is String
            ? jsonDecode(rawScores)
            : rawScores) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, (v as num).toDouble()));

    final criteriaList = ((rawCrit is String
            ? jsonDecode(rawCrit)
            : rawCrit) as List)
        .map((c) => EvaluationCriterion.fromMap(c as Map<String, dynamic>))
        .toList();

    return Evaluation(
      id:          m['id'] as String,
      companyId:   m['company_id'] as String,
      employeeId:  m['employee_id'] as String,
      reviewerId:  m['reviewer_id'] as String? ?? '',
      period:      m['period'] as String? ?? '',
      criteria:    criteriaList,
      scores:      scoresMap,
      totalScore:  (m['total_score'] as num).toDouble(),
      maxScore:    (m['max_score'] as num).toDouble(),
      notes:       m['notes'] as String?,
      createdAt:   DateTime.parse(m['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'id':          id,
        'company_id':  companyId,
        'employee_id': employeeId,
        'reviewer_id': reviewerId,
        'period':      period,
        'criteria':    jsonEncode(criteria.map((c) => c.toMap()).toList()),
        'scores':      jsonEncode(scores),
        'total_score': totalScore,
        'max_score':   maxScore,
        'notes':       notes,
        'created_at':  createdAt.toIso8601String(),
      };
}
