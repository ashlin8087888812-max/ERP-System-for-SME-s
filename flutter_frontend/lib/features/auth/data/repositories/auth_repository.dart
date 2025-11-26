
import '../../../../core/api/dio_client.dart';
import '../../../../core/services/auth_storage.dart';
import '../models/user_model.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; // Need to add this dependency

class AuthRepository {
  final DioClient _dioClient;
  final AuthStorage _authStorage;

  AuthRepository(this._dioClient, this._authStorage);

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _dioClient.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final token = response.data['access_token'];
      await _authStorage.saveToken(token);

      // Decode token to get user info
      // Note: In a real app, you might want to fetch the user profile from an endpoint
      // But since our JWT has the info, we can decode it.
      // However, I need to add jwt_decoder package first.
      // For now, I'll assume the JWT payload matches UserModel or I'll fetch from me endpoint if I had one.
      // Let's assume we decode it.
      
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      
      // Map JWT claims to UserModel
      // JWT: sub (id), email, company_id, role, db_name
      return UserModel(
        id: int.parse(decodedToken['sub']),
        email: decodedToken['email'],
        companyId: decodedToken['company_id'],
        role: decodedToken['role'],
        fullName: decodedToken['full_name'], // If added to JWT
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
