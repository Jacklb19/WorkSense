import 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart'
    as feature_auth;

export 'package:worksense_app/features/auth/presentation/providers/auth_provider.dart'
    show loginNotifierProvider, supabaseDataSourceProvider;

@Deprecated('Use loginNotifierProvider instead.')
final authNotifierProvider = feature_auth.loginNotifierProvider;
