import '../services/api_client.dart';
import '../services/auth_storage.dart';
import '../models/user_model.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final AuthStorage _authStorage;

  AuthRepository(this._apiClient, this._authStorage);

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final token = response.data['access_token'];
      final refreshToken = response.data['refresh_token'] as String?;
      
      // Decode JWT to extract user data
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      
      final userId = int.parse(decodedToken['sub']);
      final userEmail = decodedToken['email'];
      final companyId = decodedToken['company_id'];
      final role = decodedToken['role'];
      final fullName = decodedToken['full_name'];

      // Save complete user session securely
      await _authStorage.saveUserSession(
        accessToken: token,
        refreshToken: refreshToken,
        userId: userId,
        email: userEmail,
        companyId: companyId,
        role: role,
        fullName: fullName,
      );
      
      return UserModel(
        id: userId,
        email: userEmail,
        companyId: companyId,
        role: role,
        fullName: fullName,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authStorage.clearAll();
  }
  
  Future<bool> isLoggedIn() async {
    return await _authStorage.hasToken();
  }

  Future<String?> getStoredToken() async {
    return await _authStorage.getToken();
  }
}
