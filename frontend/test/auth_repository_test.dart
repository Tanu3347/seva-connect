import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seva_connect/core/api_client.dart';
import 'package:seva_connect/data/auth_repository.dart';
import 'package:seva_connect/data/auth_session.dart';

const responseData = {
  'token': 'test.jwt.token',
  'user': {
    'id': 'user-1',
    'name': 'Sam Volunteer',
    'email': 'sam@example.com',
    'role': 'VOLUNTEER',
  },
};

void main() {
  test('login sends credentials to the API and parses the session', () async {
    final requests = <RequestOptions>[];
    final dio = _dioForSuccess(requests);
    final repository = AuthRepository(dio);

    final session = await repository.login(
      email: ' sam@example.com ',
      password: 'password123',
    );

    expect(requests.single.uri.toString(), '${apiBaseUrl}auth/login');
    expect(requests.single.data, {
      'email': 'sam@example.com',
      'password': 'password123',
    });
    expect(session.token, 'test.jwt.token');
    expect(session.role, UserRole.volunteer);
  });

  test('registration sends the selected role to the API', () async {
    final requests = <RequestOptions>[];
    final dio = _dioForSuccess(requests);
    final repository = AuthRepository(dio);

    await repository.register(
      name: 'Sam Volunteer',
      email: 'sam@example.com',
      password: 'password123',
      role: UserRole.ngo,
    );

    expect(requests.single.uri.toString(), '${apiBaseUrl}auth/register');
    expect(requests.single.data['role'], 'NGO');
  });

  test('login surfaces the API error message', () async {
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 401,
                data: {'error': 'Invalid email or password'},
              ),
            ),
          );
        },
      ),
    );
    final repository = AuthRepository(dio);

    await expectLater(
      repository.login(email: 'sam@example.com', password: 'wrongpass'),
      throwsA(
        isA<AuthException>().having(
          (error) => error.message,
          'message',
          'Invalid email or password',
        ),
      ),
    );
  });
}

Dio _dioForSuccess(List<RequestOptions> requests) {
  final dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        requests.add(options);
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 201,
            data: responseData,
          ),
        );
      },
    ),
  );
  return dio;
}
