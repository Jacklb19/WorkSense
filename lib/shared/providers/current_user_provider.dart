import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AppRole {
  superAdmin,
  admin,
  cameraMonitor,
  employee,
}

class CurrentUser {
  final User? user;
  final AppRole role;
  final String? companyId;

  const CurrentUser({
    this.user,
    required this.role,
    this.companyId,
  });
}

final currentUserProvider = StreamProvider<CurrentUser>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map((authState) {
    final user = authState.session?.user;
    if (user == null) {
      return const CurrentUser(user: null, role: AppRole.employee, companyId: null);
    }

    final userMeta = user.userMetadata ?? {};
    final appMeta = user.appMetadata ?? {};
    
    // El rol puede venir del backend (app_meta_data) o del signup (user_meta_data)
    final rawRole = (appMeta['role']?.toString() ?? userMeta['role']?.toString())?.toUpperCase();
    var companyId = (appMeta['company_id']?.toString() ?? userMeta['company_id']?.toString());
    if (companyId == 'default' || companyId == '') {
      companyId = null;
    }

    AppRole role;
    switch (rawRole) {
      case 'SUPER_ADMIN':
        role = AppRole.superAdmin;
        break;
      case 'ADMIN':
        role = AppRole.admin;
        break;
      case 'CAMERA_MONITOR':
        role = AppRole.cameraMonitor;
        break;
      case 'EMPLOYEE':
      default:
        role = AppRole.employee;
        break;
    }

    return CurrentUser(user: user, role: role, companyId: companyId);
  });
});
