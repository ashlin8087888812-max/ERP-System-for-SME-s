import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthLogin>(_onLogin);
    on<AuthLogout>(_onLogout);
  }

  Future<void> _onCheckStatus(AuthCheckStatus event, Emitter<AuthState> emit) async {
    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      if (isLoggedIn) {
        // Ideally we should fetch user info or decode token again
        // For now, just emit authenticated with a placeholder or stored user if we persisted it
        // Since we don't have persistence for user model yet, we might need to decode token again
        // But AuthRepository.login returns UserModel.
        // Let's assume for now we just go to Unauthenticated if we can't restore user easily without a call.
        // Or better, let's make AuthRepository have a method to get current user from token.
        
        // For this iteration, I'll emit AuthUnauthenticated if I can't easily get the user, 
        // or I'll implement getUserFromToken in repo.
        // Let's assume we force re-login for now or implement getUserFromToken.
        // Actually, let's try to get the user.
        // But I can't change repo easily in this step.
        // I'll emit AuthUnauthenticated to force login for now, or check if I can decode token here.
        // Wait, I can't access storage here directly.
        
        // Let's just emit AuthUnauthenticated for now to be safe, or AuthAuthenticated with dummy if we just want to bypass login.
        // Correct approach: AuthRepository should have `getCurrentUser()`
        emit(AuthUnauthenticated()); 
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(AuthLogin event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(event.email, event.password);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogout(AuthLogout event, Emitter<AuthState> emit) async {
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }
}
