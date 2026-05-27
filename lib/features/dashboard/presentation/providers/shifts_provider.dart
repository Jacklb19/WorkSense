import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/data/datasources/local/database.dart' as local_db;
import 'package:worksense_app/domain/entities/shift.dart';
import 'package:worksense_app/domain/repositories/shift_repository.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart'
    show appDatabaseProvider;
import 'package:worksense_app/data/repositories/shift_repository_impl.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';
import 'package:worksense_app/features/dashboard/domain/usecases/save_shift_use_case.dart';

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncRepo = ref.watch(syncRepositoryProvider);
  return ShiftRepositoryImpl(db, syncRepo);
});

final saveShiftUseCaseProvider = Provider<SaveShiftUseCase>((ref) {
  final repo = ref.watch(shiftRepositoryProvider);
  return SaveShiftUseCase(repo);
});

// ── Delete Shift Use Case ────────────────────────────────────────────────────

class DeleteShiftUseCase {
  final ShiftRepository _repo;
  DeleteShiftUseCase(this._repo);
  Future<void> call(String shiftId) => _repo.deleteShift(shiftId);
}

final deleteShiftUseCaseProvider = Provider<DeleteShiftUseCase>((ref) {
  return DeleteShiftUseCase(ref.watch(shiftRepositoryProvider));
});

final shiftsProvider = FutureProvider<List<Shift>>((ref) async {
  // ✅ Usa .future para ESPERAR a que el stream emita su primer valor.
  //    Con .valueOrNull, si el stream aún no emitió, companyId sería null
  //    y devolvería [] permanentemente hasta que algo invalide el provider.
  final user = await ref.watch(currentUserProvider.future);
  final repo = ref.watch(shiftRepositoryProvider);

  final companyId = user.companyId;
  if (companyId == null || companyId.isEmpty) return [];

  // Depend on sync trigger for refresh
  ref.watch(syncNotifierProvider);

  // 1. Try local DB first
  var shifts = await repo.getShifts(companyId);

  // 2. If local DB is empty, pull from Supabase and seed the local DB
  if (shifts.isEmpty) {
    final remote = ref.read(supabaseDataSourceProvider);
    final db = ref.read(appDatabaseProvider);

    try {
      final remoteShifts = await remote.fetchAllShifts(companyId);
      for (final s in remoteShifts) {
        final startParts = (s['start_time'] as String).split(':');
        final endParts = (s['end_time'] as String).split(':');
        final breakStartParts = (s['break_time_start'] as String?)?.split(':');
        final breakEndParts = (s['break_time_end'] as String?)?.split(':');

        await db.insertShiftRecord(
          local_db.ShiftRecordsCompanion(
            id: Value(s['id'] as String),
            companyId: Value(s['company_id'] as String),
            name: Value(s['name'] as String? ?? 'Turno'),
            startHour: Value(int.parse(startParts[0])),
            startMinute: Value(int.parse(startParts[1])),
            endHour: Value(int.parse(endParts[0])),
            endMinute: Value(int.parse(endParts[1])),
            breakStartHour:
                Value(breakStartParts != null ? int.parse(breakStartParts[0]) : null),
            breakStartMinute:
                Value(breakStartParts != null ? int.parse(breakStartParts[1]) : null),
            breakEndHour:
                Value(breakEndParts != null ? int.parse(breakEndParts[0]) : null),
            breakEndMinute:
                Value(breakEndParts != null ? int.parse(breakEndParts[1]) : null),
            createdAt: Value(
              s['created_at'] != null
                  ? DateTime.parse(s['created_at'] as String)
                  : DateTime.now(),
            ),
          ),
        );
      }

      // Re-read from local DB after seeding
      shifts = await repo.getShifts(companyId);
      debugPrint('[shiftsProvider] Seeded ${shifts.length} shifts from Supabase.');
    } catch (e) {
      debugPrint('[shiftsProvider] Supabase fallback failed: $e');
    }
  }

  return shifts;
});

// ── Shift Form State ────────────────────────────────────────────────────────

class ShiftFormState {
  final bool isLoading;
  final String? errorMessage;
  final bool saved;

  const ShiftFormState({
    this.isLoading = false,
    this.errorMessage,
    this.saved = false,
  });

  ShiftFormState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? saved,
  }) {
    return ShiftFormState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      saved: saved ?? this.saved,
    );
  }
}

// ── Shift Form Notifier ─────────────────────────────────────────────────────

class ShiftFormNotifier extends StateNotifier<ShiftFormState> {
  final Ref _ref;

  ShiftFormNotifier(this._ref) : super(const ShiftFormState());

  void reset() => state = const ShiftFormState();

  Future<void> saveShift({
    required String id,
    required String name,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
    int? breakStartHour,
    int? breakStartMinute,
    int? breakEndHour,
    int? breakEndMinute,
    bool isEdit = false,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userState = _ref.read(currentUserProvider);
      final companyId = userState.valueOrNull?.companyId;

      if (companyId == null || companyId.isEmpty) {
        throw Exception('Compañía no identificada.');
      }

      final repo = _ref.read(shiftRepositoryProvider);

      final shift = Shift(
        id: id,
        companyId: companyId,
        name: name,
        startTime: TimeOfDay(hour: startHour, minute: startMinute),
        endTime: TimeOfDay(hour: endHour, minute: endMinute),
        breakStartTime: breakStartHour != null && breakStartMinute != null
            ? TimeOfDay(hour: breakStartHour, minute: breakStartMinute)
            : null,
        breakEndTime: breakEndHour != null && breakEndMinute != null
            ? TimeOfDay(hour: breakEndHour, minute: breakEndMinute)
            : null,
        createdAt: DateTime.now(),
      );

      if (isEdit) {
        await repo.updateShift(shift);
      } else {
        await repo.createShift(shift);
      }

      // Invalidate to reload the list
      _ref.invalidate(shiftsProvider);
      
      state = state.copyWith(isLoading: false, saved: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final shiftFormNotifierProvider =
    StateNotifierProvider.autoDispose<ShiftFormNotifier, ShiftFormState>((ref) {
  return ShiftFormNotifier(ref);
});
