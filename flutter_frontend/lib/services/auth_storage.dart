import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:developer' as developer;

/// Enterprise-grade secure storage for authentication tokens and user session data.
/// 
/// Features:
/// - Platform-specific encryption (AES256 on Android, Keychain on iOS)
/// - Automatic token expiration validation
/// - Refresh token support
/// - Secure user metadata storage
/// - Comprehensive error handling and logging
class AuthStorage {
  final FlutterSecureStorage _storage;

  // Storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _companyIdKey = 'company_id';
  static const String _roleKey = 'user_role';
  static const String _fullNameKey = 'full_name';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _lastLoginKey = 'last_login';

  AuthStorage(this._storage);

  // ==================== Token Management ====================

  /// Save access token with automatic expiration tracking
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _accessTokenKey, value: token);
      
      // Extract and store expiration time from JWT
      if (!JwtDecoder.isExpired(token)) {
        final decoded = JwtDecoder.decode(token);
        final exp = decoded['exp'] as int?;
        if (exp != null) {
          await _storage.write(
            key: _tokenExpiryKey,
            value: exp.toString(),
          );
        }
      }
      
      developer.log('Access token saved securely', name: 'AuthStorage');
    } catch (e) {
      developer.log('Error saving token: $e', name: 'AuthStorage', error: e);
      rethrow;
    }
  }

  /// Retrieve access token if valid and not expired
  Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: _accessTokenKey);
      
      if (token == null || token.isEmpty) {
        return null;
      }

      // Validate token is not expired
      if (JwtDecoder.isExpired(token)) {
        developer.log('Token expired, clearing storage', name: 'AuthStorage');
        await deleteToken();
        return null;
      }

      return token;
    } catch (e) {
      developer.log('Error reading token: $e', name: 'AuthStorage', error: e);
      return null;
    }
  }

  /// Save refresh token for token renewal
  Future<void> saveRefreshToken(String refreshToken) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
      developer.log('Refresh token saved securely', name: 'AuthStorage');
    } catch (e) {
      developer.log('Error saving refresh token: $e', name: 'AuthStorage', error: e);
      rethrow;
    }
  }

  /// Retrieve refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      developer.log('Error reading refresh token: $e', name: 'AuthStorage', error: e);
      return null;
    }
  }

  /// Check if token exists and is valid
  Future<bool> hasValidToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Check if token is expired (legacy method for compatibility)
  Future<bool> hasToken() async {
    return await hasValidToken();
  }

  /// Get token expiration timestamp
  Future<DateTime?> getTokenExpiry() async {
    try {
      final expiryStr = await _storage.read(key: _tokenExpiryKey);
      if (expiryStr != null) {
        final timestamp = int.tryParse(expiryStr);
        if (timestamp != null) {
          return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        }
      }
      return null;
    } catch (e) {
      developer.log('Error reading token expiry: $e', name: 'AuthStorage', error: e);
      return null;
    }
  }

  /// Check if token will expire soon (within next 5 minutes)
  Future<bool> isTokenExpiringSoon() async {
    try {
      final expiry = await getTokenExpiry();
      if (expiry == null) return true;
      
      final now = DateTime.now();
      final difference = expiry.difference(now);
      
      return difference.inMinutes < 5;
    } catch (e) {
      developer.log('Error checking token expiry: $e', name: 'AuthStorage', error: e);
      return true;
    }
  }

  // ==================== User Metadata Management ====================

  /// Save complete user session data
  Future<void> saveUserSession({
    required String accessToken,
    String? refreshToken,
    required int userId,
    required String email,
    required int companyId,
    required String role,
    String? fullName,
  }) async {
    try {
      await saveToken(accessToken);
      
      if (refreshToken != null) {
        await saveRefreshToken(refreshToken);
      }

      await _storage.write(key: _userIdKey, value: userId.toString());
      await _storage.write(key: _userEmailKey, value: email);
      await _storage.write(key: _companyIdKey, value: companyId.toString());
      await _storage.write(key: _roleKey, value: role);
      
      if (fullName != null) {
        await _storage.write(key: _fullNameKey, value: fullName);
      }

      await _storage.write(
        key: _lastLoginKey,
        value: DateTime.now().toIso8601String(),
      );

      developer.log('User session saved securely', name: 'AuthStorage');
    } catch (e) {
      developer.log('Error saving user session: $e', name: 'AuthStorage', error: e);
      rethrow;
    }
  }

  /// Get user ID from secure storage
  Future<int?> getUserId() async {
    try {
      final idStr = await _storage.read(key: _userIdKey);
      return idStr != null ? int.tryParse(idStr) : null;
    } catch (e) {
      developer.log('Error reading user ID: $e', name: 'AuthStorage', error: e);
      return null;
    }
  }

  /// Get user email from secure storage
  Future<String?> getUserEmail() async {
    try {
      return await _storage.read(key: _userEmailKey);
    } catch (e) {
      developer.log('Error reading user email: $e', name: 'AuthStorage', error: e);
      return null;
    }
  }

  /// Get company ID from secure storage
  Future<int?> getCompanyId() async {
    try {
      final idStr = await _storage.read(key: _companyIdKey);
      return idStr != null ? int.tryParse(idStr) : null;
    } catch (e) {
      developer.log('Error reading company ID: $e', name: 'AuthStorage', error: e);
      return null;
    }
  }

  /// Get user role from secure storage
  Future<String?> getUserRole() async {
    try {
      return await _storage.read(key: _roleKey);
    } catch (e) {
      developer.log('Error reading user role: $e', name: 'AuthStorage', error: e);
      return null;
    }
  }

  /// Get full name from secure storage
  Future<String?> getFullName() async {
    try {
      return await _storage.read(key: _fullNameKey);
    } catch (e) {
      developer.log('Error reading full name: $e', name: 'AuthStorage', error: e);
      return null;
    }
  }

  /// Get last login timestamp
  Future<DateTime?> getLastLogin() async {
    try {
      final loginStr = await _storage.read(key: _lastLoginKey);
      return loginStr != null ? DateTime.tryParse(loginStr) : null;
    } catch (e) {
      developer.log('Error reading last login: $e', name: 'AuthStorage', error: e);
      return null;
    }
  }

  // ==================== Session Management ====================

  /// Delete access token only
  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _tokenExpiryKey);
      developer.log('Access token deleted', name: 'AuthStorage');
    } catch (e) {
      developer.log('Error deleting token: $e', name: 'AuthStorage', error: e);
      rethrow;
    }
  }

  /// Clear all authentication data (logout)
  Future<void> clearAll() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _userIdKey);
      await _storage.delete(key: _userEmailKey);
      await _storage.delete(key: _companyIdKey);
      await _storage.delete(key: _roleKey);
      await _storage.delete(key: _fullNameKey);
      await _storage.delete(key: _tokenExpiryKey);
      await _storage.delete(key: _lastLoginKey);
      
      developer.log('All auth data cleared', name: 'AuthStorage');
    } catch (e) {
      developer.log('Error clearing storage: $e', name: 'AuthStorage', error: e);
      rethrow;
    }
  }

  /// Get all stored keys (for debugging - use with caution)
  Future<Map<String, String>> getAllSecureData() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      developer.log('Error reading all data: $e', name: 'AuthStorage', error: e);
      return {};
    }
  }
}
