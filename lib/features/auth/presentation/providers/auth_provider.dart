import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/data/datasources/remote/supabase_datasource.dart';
import 'package:worksense_app/data/repositories/auth_repository_impl.dart';
import 'package:worksense_app/domain/repositories/auth_repository.dart';
import 'package:worksense_app/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:worksense_app/features/auth/domain/usecases/sign_out_use_case.dart';

// â”€â”€ Data Sources â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final supabaseDataSourceProvider = Provider<SupabaseDataSource>((ref) {
  return SupabaseDataSource();
});

// â”€â”€ Repositories â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(supabaseDataSourceProvider);
  return AuthRepositoryImpl(dataSource);
});

// â”€â”€ Use Cases â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return SignInUseCase(repo);
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return SignOutUseCase(repo);
});

// â”€â”€ Auth State â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final isAuthenticatedProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.isAuthenticated;
});

final currentUserEmailProvider = Provider<String?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.currentUserEmail;
});

// â”€â”€ Login State Notifier â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class LoginState {
  final bool isLoading;
  final String? errorMessage;

  const LoginState({
    this.isLoading = false,
    this.errorMessage,
  });

  LoginState copyWith({bool? isLoading, String? errorMessage}) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class LoginNotifier extends StateNotifier<LoginState> {
  final SignInUseCase _signInUseCase;
  final SignOutUseCase _signOutUseCase;

  LoginNotifier(this._signInUseCase, this._signOutUseCase)
      : super(const LoginState());

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _signInUseCase(email: email, password: password);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(e),
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _signOutUseCase();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _parseError(e),
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  String _parseError(Object e) {
    final message = e.toString();
    if (message.contains('Invalid login credentials')) {
      return 'Correo o contraseÃ±a incorrectos.';
    }
    if (message.contains('network') || message.contains('SocketException')) {
      return 'Sin conexiÃ³n a internet. Verifica tu red.';
    }
    return 'Error inesperado. Intenta de nuevo.';
  }
}

final loginNotifierProvider =
    StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  final signIn = ref.watch(signInUseCaseProvider);
  final signOut = ref.watch(signOutUseCaseProvider);
  return LoginNotifier(signIn, signOut);
});

