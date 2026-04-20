import 'package:worksense_app/data/datasources/remote/supabase_datasource.dart';
import 'package:worksense_app/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) =>
      _dataSource.signIn(email: email, password: password);

  @override
  Future<void> signOut() => _dataSource.signOut();

  @override
  Stream<bool> get isAuthenticated => _dataSource.authStateStream;

  @override
  String? get currentUserEmail => _dataSource.currentUserEmail;
}
