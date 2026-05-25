import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worksense_app/domain/entities/evaluation.dart';

/// Repositorio de evaluaciones de desempeño — almacenamiento en Supabase.
class EvaluationRepository {
  EvaluationRepository._();
  static final EvaluationRepository instance = EvaluationRepository._();

  final _client = Supabase.instance.client;

  // ── Evaluations ───────────────────────────────────────────────────────────

  /// Todas las evaluaciones de la empresa (admin).
  Future<List<Evaluation>> fetchByCompany(String companyId) async {
    try {
      final rows = await _client
          .from('evaluations')
          .select()
          .eq('company_id', companyId)
          .order('created_at', ascending: false);
      return (rows as List)
          .map((r) => Evaluation.fromMap(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Evaluaciones de un empleado específico.
  Future<List<Evaluation>> fetchByEmployee(String employeeId) async {
    try {
      final rows = await _client
          .from('evaluations')
          .select()
          .eq('employee_id', employeeId)
          .order('created_at', ascending: false);
      return (rows as List)
          .map((r) => Evaluation.fromMap(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Detalle de una evaluación.
  Future<Evaluation?> fetchById(String id) async {
    try {
      final row = await _client
          .from('evaluations')
          .select()
          .eq('id', id)
          .single();
      return Evaluation.fromMap(row);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(Evaluation eval) async {
    await _client.from('evaluations').upsert(eval.toMap());
  }

  Future<void> delete(String id) async {
    await _client.from('evaluations').delete().eq('id', id);
  }

  /// Promedio global de desempeño por empleado.
  /// Retorna mapa employeeId → porcentaje promedio.
  Future<Map<String, double>> fetchAverageScores(String companyId) async {
    try {
      final rows = await _client
          .from('evaluations')
          .select('employee_id, total_score, max_score')
          .eq('company_id', companyId);
      final totals = <String, List<double>>{};
      for (final r in (rows as List)) {
        final empId = r['employee_id'] as String;
        final pct = (r['max_score'] as num) > 0
            ? (r['total_score'] as num) / (r['max_score'] as num) * 100
            : 0.0;
        totals.putIfAbsent(empId, () => []).add(pct.toDouble());
      }
      return totals.map(
          (k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length));
    } catch (_) {
      return {};
    }
  }
}
