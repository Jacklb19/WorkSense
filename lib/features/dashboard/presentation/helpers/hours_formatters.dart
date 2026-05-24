class HoursFormatters {
  static String formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours <= 0) return '${remainder}m';
    return '${hours}h ${remainder}m';
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours <= 0) return '${duration.inMinutes}m';
    return '${hours}h ${minutes}m';
  }

  static String formatAnomalyLabel(String value) {
    switch (value) {
      case 'open_session':
        return 'Hay una sesion sin cierre confirmado.';
      case 'too_many_segments':
        return 'Se detectaron demasiadas entradas o salidas en el dia.';
      case 'repeated_absence_events':
        return 'Se registraron varias ausencias durante la jornada.';
      default:
        return value.replaceAll('_', ' ');
    }
  }
}
