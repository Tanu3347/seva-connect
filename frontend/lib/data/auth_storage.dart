import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'auth_session.dart';

class AuthStorage {
  static const _sessionKey = 'seva_connect.auth_session';

  Future<AuthSession?> readSession() async {
    final preferences = await SharedPreferences.getInstance();
    final json = preferences.getString(_sessionKey);
    if (json == null) return null;

    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The saved sign-in session is invalid.');
    }
    return AuthSession.fromJson(decoded);
  }

  Future<String?> readToken() async => (await readSession())?.token;

  Future<void> saveSession(AuthSession session) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _sessionKey,
      jsonEncode(session.toJson()),
    );
    if (!saved) {
      throw StateError('Could not save the sign-in session on this device.');
    }
  }

  Future<void> clearSession() async {
    final preferences = await SharedPreferences.getInstance();
    final removed = await preferences.remove(_sessionKey);
    if (!removed && preferences.containsKey(_sessionKey)) {
      throw StateError('Could not clear the saved sign-in session.');
    }
  }
}
