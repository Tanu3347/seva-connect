import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seva_connect/core/api_client.dart';
import 'package:seva_connect/data/profile_repository.dart';

Map<String, dynamic> profileJson({
  String name = 'Sam Volunteer',
  String? bio = 'Helping the community.',
  String? location = 'Northside',
  List<String> interests = const ['Education'],
  List<String> skills = const ['Teaching'],
}) => {
  'id': 'volunteer-1',
  'email': 'sam@example.com',
  'role': 'VOLUNTEER',
  'name': name,
  'bio': bio,
  'location': location,
  'interests': interests,
  'skills': skills,
};

void main() {
  test('loads profile from the authenticated profile endpoint', () async {
    final requests = <RequestOptions>[];
    final repository = ProfileRepository(
      _dio(requests, (_) => {'profile': profileJson()}),
    );

    final profile = await repository.getMyProfile();

    expect(requests.single.uri.toString(), '${apiBaseUrl}profile/me');
    expect(requests.single.method, 'GET');
    expect(profile.name, 'Sam Volunteer');
    expect(profile.location, 'Northside');
    expect(profile.interests, ['Education']);
    expect(profile.skills, ['Teaching']);
  });

  test('updates profile and parses the saved response', () async {
    final requests = <RequestOptions>[];
    final repository = ProfileRepository(
      _dio(
        requests,
        (_) => {
          'profile': profileJson(
            name: 'Updated Sam',
            bio: 'New bio',
            location: 'Eastside',
            interests: ['Environment'],
            skills: ['First aid'],
          ),
        },
      ),
    );

    final profile = await repository.updateMyProfile(
      name: ' Updated Sam ',
      bio: ' New bio ',
      location: ' Eastside ',
      interests: ['Environment'],
      skills: ['First aid'],
    );

    expect(requests.single.uri.toString(), '${apiBaseUrl}profile/me');
    expect(requests.single.method, 'PATCH');
    expect(requests.single.data, {
      'name': 'Updated Sam',
      'bio': 'New bio',
      'location': 'Eastside',
      'interests': ['Environment'],
      'skills': ['First aid'],
    });
    expect(profile.name, 'Updated Sam');
    expect(profile.interests, ['Environment']);
  });

  test('shows backend validation messages clearly', () async {
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 400,
              data: {'error': 'Name must be a non-empty string'},
            ),
          ),
        ),
      ),
    );
    final repository = ProfileRepository(dio);

    await expectLater(
      repository.updateMyProfile(
        name: '',
        bio: '',
        location: '',
        interests: const [],
        skills: const [],
      ),
      throwsA(
        isA<ProfileApiException>().having(
          (error) => error.message,
          'message',
          'Name must be a non-empty string',
        ),
      ),
    );
  });
}

Dio _dio(
  List<RequestOptions> requests,
  Map<String, dynamic> Function(RequestOptions options) respond,
) {
  final dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        requests.add(options);
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: respond(options),
          ),
        );
      },
    ),
  );
  return dio;
}
