import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worksense_app/domain/entities/app_role.dart';

export 'package:worksense_app/domain/entities/app_role.dart';

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
    
    final role = AppRoleX.fromRaw(
      appMeta['role'] ?? userMeta['role'],
    );
    var companyId = (appMeta['company_id']?.toString() ?? userMeta['company_id']?.toString());
    if (companyId == 'default' || companyId == '') {
      companyId = null;
    }

    return CurrentUser(user: user, role: role, companyId: companyId);
  });
});
