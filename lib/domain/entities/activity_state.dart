import 'package:flutter/material.dart';
import 'package:worksense_app/core/theme/app_colors.dart';

enum ActivityState {
  trabajando,
  inactivo,
  distraido,
  fatiga,
  ausente,
  fueraDelArea,
  noIdentificado;

  String get label {
    switch (this) {
      case ActivityState.trabajando:
        return 'TRABAJANDO';
      case ActivityState.inactivo:
        return 'INACTIVO';
      case ActivityState.distraido:
        return 'DISTRAÍDO';
      case ActivityState.fatiga:
        return 'FATIGA';
      case ActivityState.ausente:
        return 'AUSENTE';
      case ActivityState.fueraDelArea:
        return 'FUERA DEL ÁREA';
      case ActivityState.noIdentificado:
        return 'NO IDENTIFICADO';
    }
  }

  String get emoji {
    switch (this) {
      case ActivityState.trabajando:
        return '🟢';
      case ActivityState.inactivo:
        return '🟡';
      case ActivityState.distraido:
        return '🟠';
      case ActivityState.fatiga:
        return '🔴';
      case ActivityState.ausente:
        return '⚫';
      case ActivityState.fueraDelArea:
        return '🔵';
      case ActivityState.noIdentificado:
        return '⬜';
    }
  }

  Color get color {
    switch (this) {
      case ActivityState.trabajando:
        return AppColors.stateWorking;
      case ActivityState.inactivo:
        return AppColors.stateInactive;
      case ActivityState.distraido:
        return AppColors.stateDistracted;
      case ActivityState.fatiga:
        return AppColors.stateFatigue;
      case ActivityState.ausente:
        return AppColors.stateAbsent;
      case ActivityState.fueraDelArea:
        return AppColors.stateOutsideArea;
      case ActivityState.noIdentificado:
        return AppColors.stateNotIdentified;
    }
  }
}
