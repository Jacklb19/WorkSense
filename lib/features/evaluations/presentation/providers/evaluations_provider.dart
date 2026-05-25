import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/domain/entities/evaluation.dart';
import 'package:worksense_app/features/evaluations/data/evaluation_repository.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

// ── Evaluaciones de la empresa (admin) ───────────────────────────────────────

final companyEvaluationsProvider =
    AsyncNotifierProvider<CompanyEvaluationsNotifier, List<Evaluation>>(
  CompanyEvaluationsNotifier.new,
);

class CompanyEvaluationsNotifier
    extends AsyncNotifier<List<Evaluation>> {
  @override
  Future<List<Evaluation>> build() => _fetch();

  Future<List<Evaluation>> _fetch() async {
    final companyId =
        ref.read(currentUserProvider).valueOrNull?.companyId ?? '';
    if (companyId.isEmpty) return [];
    return EvaluationRepository.instance.fetchByCompany(companyId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<String?> save(Evaluation eval) async {
    try {
      await EvaluationRepository.instance.save(eval);
      await refresh();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> delete(String id) async {
    await EvaluationRepository.instance.delete(id);
    await refresh();
  }
}

// ── Evaluaciones del empleado actual ─────────────────────────────────────────

final myEvaluationsProvider =
    AsyncNotifierProvider<MyEvaluationsNotifier, List<Evaluation>>(
  MyEvaluationsNotifier.new,
);

class MyEvaluationsNotifier extends AsyncNotifier<List<Evaluation>> {
  @override
  Future<List<Evaluation>> build() => _fetch();

  Future<List<Evaluation>> _fetch() async {
    final userId =
        ref.read(currentUserProvider).valueOrNull?.user?.id;
    if (userId == null) return [];
    return EvaluationRepository.instance.fetchByEmployee(userId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

// ── Detalle de una evaluación ─────────────────────────────────────────────────

final evaluationDetailProvider =
    FutureProviderFamily<Evaluation?, String>(
  (ref, id) => EvaluationRepository.instance.fetchById(id),
);

// ── Promedios por empleado ────────────────────────────────────────────────────

final employeeAvgScoresProvider =
    FutureProvider<Map<String, double>>((ref) async {
  final companyId =
      ref.watch(currentUserProvider).valueOrNull?.companyId ?? '';
  if (companyId.isEmpty) return {};
  return EvaluationRepository.instance.fetchAverageScores(companyId);
});
