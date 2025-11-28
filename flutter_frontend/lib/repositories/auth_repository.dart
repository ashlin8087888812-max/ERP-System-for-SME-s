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
      await _authStorage.saveToken(token);

      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      
      return UserModel(
        id: int.parse(decodedToken['sub']),
        email: decodedToken['email'],
        companyId: decodedToken['company_id'],
        role: decodedToken['role'],
        fullName: decodedToken['full_name'],
      );
    } catch (e) {
      throw e;
    }
  }

  Future<void> logout() async {
    await _authStorage.deleteToken();
  }
  
  Future<bool> isLoggedIn() async {
    return await _authStorage.hasToken();
  }

  Future<String?> getStoredToken() async {
    return await _authStorage.getToken();
  }
}
