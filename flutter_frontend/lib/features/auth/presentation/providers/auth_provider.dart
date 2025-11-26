import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';
import '../../../../injection_container.dart' as di;

// Auth State
class AuthState {
  final bool isLoading;
  final String? error;
  final UserModel? user;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    UserModel? user,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _authRepository.login(email, password);
      
      state = state.copyWith(
        isLoading: false,
        user: user,
        isAuthenticated: true,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isAuthenticated: false,
      );
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
      state = AuthState(); // Reset to initial state
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      final isLoggedIn = await _authRepository.isLoggedIn();
      if (isLoggedIn) {
        // Get the stored token and decode it to restore user data
        final token = await _authRepository.getStoredToken();
        if (token != null) {
          final decodedToken = _decodeToken(token);
          final user = UserModel(
            id: int.parse(decodedToken['sub']),
            email: decodedToken['email'],
            companyId: decodedToken['company_id'],
            role: decodedToken['role'],
            fullName: decodedToken['full_name'],
          );
          state = state.copyWith(isAuthenticated: true, user: user);
        } else {
          state = state.copyWith(isAuthenticated: true);
        }
      }
    } catch (e) {
      // If token is invalid, clear auth state
      state = AuthState();
    }
  }

  Map<String, dynamic> _decodeToken(String token) {
    // Simple JWT decode (you can use jwt_decoder package for production)
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }
    
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return json.decode(decoded);
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(di.sl<AuthRepository>());
});
