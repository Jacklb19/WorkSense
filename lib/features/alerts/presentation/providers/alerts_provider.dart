import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';

class AlertMessage {
  final String text;
  final Color backgroundColor;
  
  AlertMessage(this.text, this.backgroundColor);
}

class AlertsNotifier extends StateNotifier<AlertMessage?> {
  final Ref ref;
  Timer? _timer;
  
  ActivityState _currentState = ActivityState.trabajando;
  int _secondsInState = 0;
  bool _alertSent = false;

  AlertsNotifier(this.ref) : super(null) {
    // Suscribirse a los cambios de estado del KioskProvider
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

    // Solo iniciamos el temporizador si es un estado que requiere alerta
    if (newState == ActivityState.ausente || newState == ActivityState.distraido) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _secondsInState++;
        _checkThresholds();
      });
    }
  }

  void _checkThresholds() {
    if (_alertSent) return; // Solo una vez por episodio

    if (_currentState == ActivityState.ausente && _secondsInState >= 60) {
      _alertSent = true;
      state = AlertMessage(
        '⚠️ Empleado ausente del puesto',
        const Color(0xFFEA4335), // Rojo
      );
    } else if (_currentState == ActivityState.distraido && _secondsInState >= 45) {
      _alertSent = true;
      state = AlertMessage(
        '⚠️ Empleado distraído',
        const Color(0xFFFFC107), // Amarillo
      );
    }
  }

  // Permite limpiar la alerta actual luego de mostrarla
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
