import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:worksense_app/data/repositories/shift_repository_impl.dart';
import 'package:worksense_app/domain/entities/shift.dart';
import 'package:worksense_app/domain/repositories/shift_repository.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';
import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:worksense_app/data/datasources/remote/supabase_datasource.dart';

// ── Repository Provider ───────────────────────────────────────────────────────

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ShiftRepositoryImpl(db);
});

// ── Shift List ────────────────────────────────────────────────────────────────

final shiftsStreamProvider = StreamProvider<List<Shift>>((ref) {
  final repo = ref.watch(shiftRepositoryProvider);
  return repo.watchShifts();
});

final employeeShiftsStreamProvider = StreamProvider.family<List<Shift>, String>((ref, employeeId) {
  final repo = ref.watch(shiftRepositoryProvider);
  return repo.watchShiftsByEmployee(employeeId);
});

// ── Shift Form State ──────────────────────────────────────────────────────────

class ShiftFormState {
  final bool isLoading;
  final bool saved;
  final String? errorMessage;

  const ShiftFormState({
    this.isLoading = false,
    this.saved = false,
    this.errorMessage,
  });

  ShiftFormState copyWith({
    bool? isLoading,
    bool? saved,
    String? errorMessage,
  }) {
    return ShiftFormState(
      isLoading: isLoading ?? this.isLoading,
      saved: saved ?? this.saved,
      errorMessage: errorMessage,
    );
  }
}

class ShiftFormNotifier extends StateNotifier<ShiftFormState> {
  final ShiftRepository _localRepo;
  final SupabaseDataSource _remoteDataSource;

  ShiftFormNotifier(this._localRepo, this._remoteDataSource)
      : super(const ShiftFormState());

  Future<void> saveShift({
    required String employeeId,
    required DateTime startTime,
    required DateTime endTime,
    String status = 'active',
    String? notes,
    String? existingId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, saved: false);

    try {
      final shift = Shift(
        id: existingId ?? const Uuid().v4(),
        employeeId: employeeId,
        startTime: startTime,
        endTime: endTime,
        status: status,
        notes: notes,
        createdAt: DateTime.now(),
      );

      // Save locally
      await _localRepo.saveShift(shift);

      // Try to sync remotely (best effort)
      try {
        await _remoteDataSource.insertShift(shift.toMap());
      } catch (_) {
        // Remote sync failed — local save succeeded, will sync later
      }

      state = state.copyWith(isLoading: false, saved: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al guardar turno: $e',
      );
    }
  }

  Future<void> deleteShift(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _localRepo.deleteShift(id);
      
      // Try to delete remotely
      try {
        await _remoteDataSource.deleteShift(id);
      } catch (_) {}

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al eliminar turno: $e',
      );
    }
  }

  void reset() {
    state = const ShiftFormState();
  }
}

final shiftFormNotifierProvider =
    StateNotifierProvider<ShiftFormNotifier, ShiftFormState>((ref) {
  final repo = ref.watch(shiftRepositoryProvider);
  final remoteDs = ref.watch(supabaseDataSourceProvider);
  return ShiftFormNotifier(repo, remoteDs);
});
