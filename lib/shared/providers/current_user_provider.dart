import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worksense_app/domain/entities/app_role.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart' show appDatabaseProvider;

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

String? _getMetadataKey(Map<String, dynamic>? metadata, String key) {
  if (metadata == null) return null;
  final lowerKey = key.toLowerCase();
  for (final k in metadata.keys) {
    if (k.toLowerCase() == lowerKey) {
      return metadata[k]?.toString();
    }
  }
  if (lowerKey == 'company_id') {
    for (final k in metadata.keys) {
      final lk = k.toLowerCase();
      if (lk == 'companyid' || lk == 'company_id') {
        return metadata[k]?.toString();
      }
    }
  }
  return null;
}

final currentUserProvider = StreamProvider<CurrentUser>((ref) async* {
  final client = Supabase.instance.client;

  await for (final authState in client.auth.onAuthStateChange) {
    final user = authState.session?.user;
    if (user == null) {
      yield const CurrentUser(user: null, role: AppRole.employee, companyId: null);
      continue;
    }

    final userMeta = user.userMetadata;
    final appMeta = user.appMetadata;

    final roleStr =
        _getMetadataKey(appMeta, 'role') ?? _getMetadataKey(userMeta, 'role');
    final role = AppRoleX.fromRaw(roleStr);

    // 1) Fuente confiable: tabla public.employees en Supabase
    String? companyId;
    try {
      final row = await client
          .from('employees')
          .select('company_id')
          .eq('id', user.id)
          .maybeSingle();
      companyId = row?['company_id']?.toString();
    } catch (_) {
      // Red sin conexión — se intentará JWT y luego local
    }

    // 2) JWT metadata como apoyo (si employees no respondió)
    if (companyId == null || companyId == 'default' || companyId == '') {
      final jwtCompanyId = _getMetadataKey(appMeta, 'company_id') ??
          _getMetadataKey(userMeta, 'company_id');
      if (jwtCompanyId != null && jwtCompanyId != 'default' && jwtCompanyId != '') {
        companyId = jwtCompanyId;
      }
    }

    yield CurrentUser(user: user, role: role, companyId: companyId);
  }
});
