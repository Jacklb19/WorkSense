import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/domain/entities/shift.dart';
import 'package:worksense_app/domain/repositories/shift_repository.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart' show appDatabaseProvider;
import 'package:worksense_app/data/repositories/shift_repository_impl.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncRepo = ref.watch(syncRepositoryProvider);
  return ShiftRepositoryImpl(db, syncRepo);
});

final shiftsProvider = FutureProvider<List<Shift>>((ref) async {
  final userState = ref.watch(currentUserProvider);
  final repo = ref.watch(shiftRepositoryProvider);
  
  final companyId = userState.valueOrNull?.companyId;
  if (companyId == null || companyId.isEmpty) {
    return [];
  }
  
  // Depend on sync trigger for refresh
  ref.watch(syncNotifierProvider);
  
  return repo.getShifts(companyId);
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

      await repo.createShift(shift);

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
