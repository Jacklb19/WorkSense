import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:worksense_app/core/constants/app_durations.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/domain/entities/alert_log.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

// ── In-screen alert message ───────────────────────────────────────────────────

class AlertMessage {
  final String text;
  final Color backgroundColor;

  AlertMessage(this.text, this.backgroundColor);
}

// ── Alert log stream providers ────────────────────────────────────────────────

final alertLogsProvider = StreamProvider<List<AlertLogData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final companyId = ref.watch(currentUserProvider).valueOrNull?.companyId;
  if (companyId == null || companyId.isEmpty) return Stream.value([]);
  return db.watchAlertLogsByCompany(companyId);
});

final unacknowledgedAlertCountProvider = Provider<int>((ref) {
  final logs = ref.watch(alertLogsProvider).valueOrNull ?? [];
  return logs.where((l) => !l.acknowledged).length;
});

// ── Alerts Notifier (in-screen banner + DB logging) ───────────────────────────

class AlertsNotifier extends StateNotifier<AlertMessage?> {
  final Ref ref;
  Timer? _timer;

  ActivityState _currentState = ActivityState.trabajando;
  int _secondsInState = 0;
  bool _alertSent = false;

  AlertsNotifier(this.ref) : super(null) {
    ref.listen(
      kioskProvider.select((state) => state.currentState),
      (previous, next) {
        if (previous != next) {
          _onStateChanged(next);
        }
      },
    );
  }

  void _onStateChanged(ActivityState newState) {
    _currentState = newState;
    _secondsInState = 0;
    _alertSent = false;

    _timer?.cancel();

    if (newState == ActivityState.ausente || newState == ActivityState.distraido) {
      _timer = Timer.periodic(AppDurations.alertCheckInterval, (timer) {
        _secondsInState++;
        _checkThresholds();
      });
    }
  }

  void _checkThresholds() {
    if (_alertSent) return;

    if (_currentState == ActivityState.ausente &&
        _secondsInState >= AppDurations.absenceAlertSeconds) {
      _alertSent = true;
      state = AlertMessage(AppStrings.alertAbsent, AppColors.alertAbsent);
      _logAlert(AlertType.absence, _secondsInState);
    } else if (_currentState == ActivityState.distraido &&
        _secondsInState >= AppDurations.distractionAlertSeconds) {
      _alertSent = true;
      state = AlertMessage(AppStrings.alertDistracted, AppColors.alertDistracted);
      _logAlert(AlertType.distraction, _secondsInState);
    }
  }

  void _logAlert(AlertType type, int durationSeconds) {
    final db = ref.read(appDatabaseProvider);
    final kioskState = ref.read(kioskProvider);
    final companyId = ref.read(currentUserProvider).valueOrNull?.companyId;
    if (companyId == null) return;

    db.insertAlertLog(AlertLogRecordsCompanion(
      id: Value(const Uuid().v4()),
      companyId: Value(companyId),
      employeeId: Value(kioskState.assignedEmployeeId),
      workstationId: Value(kioskState.workstationId.isEmpty ? null : kioskState.workstationId),
      alertType: Value(type.raw),
      durationSeconds: Value(durationSeconds),
      triggeredAt: Value(DateTime.now()),
      acknowledged: const Value(false),
    ));
  }

  void clearAlert() {
    state = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final alertsProvider = StateNotifierProvider<AlertsNotifier, AlertMessage?>((ref) {
  return AlertsNotifier(ref);
});
