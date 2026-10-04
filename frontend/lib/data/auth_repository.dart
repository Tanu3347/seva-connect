import 'package:dio/dio.dart';

import 'auth_session.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) => _send('auth/login', {'email': email.trim(), 'password': password});

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) => _send('auth/register', {
    'name': name.trim(),
    'email': email.trim(),
    'password': password,
    'role': role.apiValue,
  });

  Future<AuthSession> _send(String path, Map<String, Object> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body);
      final data = response.data;
      if (data == null) {
        throw const AuthException('The server returned an empty response.');
      }
      return AuthSession.fromApi(data);
    } on DioException catch (error) {
      final responseBody = error.response?.data;
      final message = responseBody is Map<String, dynamic>
          ? responseBody['error']
          : null;
      if (message is String && message.isNotEmpty) {
        throw AuthException(message);
      }
      if (error.response == null) {
        throw const AuthException(
          'Could not connect to Seva Connect. Check your connection and API URL.',
        );
      }
      throw AuthException(
        'Sign-in failed (HTTP ${error.response?.statusCode ?? 'error'}). Please try again.',
      );
    } on FormatException catch (error) {
      throw AuthException(error.message);
    }
  }
}
