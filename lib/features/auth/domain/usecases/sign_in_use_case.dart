import 'package:worksense_app/domain/repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository _repository;

  SignInUseCase(this._repository);

  Future<void> call({required String email, required String password}) =>
      _repository.signIn(email: email, password: password);
}
