enum AppRole {
  superAdmin,
  admin,
  cameraMonitor,
  employee,
}

extension AppRoleX on AppRole {
  String get metadataValue {
    switch (this) {
      case AppRole.superAdmin:
        return 'SUPER_ADMIN';
      case AppRole.admin:
        return 'ADMIN';
      case AppRole.cameraMonitor:
        return 'CAMERA_MONITOR';
      case AppRole.employee:
        return 'EMPLOYEE';
    }
  }

  String get formValue => metadataValue.toLowerCase();

  bool get canManageUsers => this == AppRole.admin || this == AppRole.superAdmin;

  static AppRole fromRaw(
    Object? raw, {
    AppRole fallback = AppRole.employee,
  }) {
    final normalized = raw?.toString().trim().toUpperCase();
    switch (normalized) {
      case 'SUPER_ADMIN':
        return AppRole.superAdmin;
      case 'ADMIN':
        return AppRole.admin;
      case 'CAMERA_MONITOR':
        return AppRole.cameraMonitor;
      case 'EMPLOYEE':
        return AppRole.employee;
      default:
        return fallback;
    }
  }
}
