enum UserRole {
  volunteer('VOLUNTEER', 'Volunteer'),
  ngo('NGO', 'NGO');

  const UserRole(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static UserRole fromApi(String value) => switch (value) {
    'VOLUNTEER' => UserRole.volunteer,
    'NGO' => UserRole.ngo,
    _ => throw FormatException('Unknown user role: $value'),
  };
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  final String token;
  final String userId;
  final String name;
  final String email;
  final UserRole role;

  factory AuthSession.fromApi(Map<String, dynamic> json) {
    final user = json['user'];
    final token = json['token'];
    if (user is! Map<String, dynamic> ||
        token is! String ||
        token.isEmpty ||
        user['id'] is! String ||
        user['name'] is! String ||
        user['email'] is! String ||
        user['role'] is! String) {
      throw const FormatException('The server returned an invalid sign-in response.');
    }

    return AuthSession(
      token: token,
      userId: user['id'] as String,
      name: user['name'] as String,
      email: user['email'] as String,
      role: UserRole.fromApi(user['role'] as String),
    );
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    final userId = json['userId'];
    final name = json['name'];
    final email = json['email'];
    final role = json['role'];
    if (token is! String ||
        userId is! String ||
        name is! String ||
        email is! String ||
        role is! String) {
      throw const FormatException('The saved sign-in session is invalid.');
    }

    return AuthSession(
      token: token,
      userId: userId,
      name: name,
      email: email,
      role: UserRole.fromApi(role),
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'userId': userId,
    'name': name,
    'email': email,
    'role': role.apiValue,
  };
}
