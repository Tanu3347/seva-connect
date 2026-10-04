import 'package:dio/dio.dart';

import 'volunteer_models.dart';
import 'volunteer_profile.dart';

class ProfileApiException implements Exception {
  const ProfileApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProfileRepository {
  const ProfileRepository(this._dio);

  final Dio _dio;

  Future<VolunteerProfile> getMyProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('profile/me');
      final data = jsonObject(response.data, 'profile');
      return VolunteerProfile.fromJson(jsonObject(data['profile'], 'profile'));
    } on DioException catch (error) {
      throw _toApiException(error, 'Could not load your profile.');
    } on FormatException catch (error) {
      throw ProfileApiException(error.message);
    }
  }

  Future<VolunteerProfile> updateMyProfile({
    required String name,
    required String bio,
    required String location,
    required List<String> interests,
    required List<String> skills,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        'profile/me',
        data: {
          'name': name.trim(),
          'bio': bio.trim(),
          'location': location.trim(),
          'interests': interests,
          'skills': skills,
        },
      );
      final data = jsonObject(response.data, 'profile');
      return VolunteerProfile.fromJson(jsonObject(data['profile'], 'profile'));
    } on DioException catch (error) {
      throw _toApiException(error, 'Could not save your profile.');
    } on FormatException catch (error) {
      throw ProfileApiException(error.message);
    }
  }

  ProfileApiException _toApiException(DioException error, String fallback) {
    final body = error.response?.data;
    final message = body is Map<String, dynamic> ? body['error'] : null;
    if (message is String && message.isNotEmpty) {
      return ProfileApiException(message);
    }
    if (error.response == null) {
      return const ProfileApiException(
        'Could not connect to Seva Connect. Check your connection and API URL.',
      );
    }
    return ProfileApiException(
      '$fallback (HTTP ${error.response?.statusCode ?? 'error'}).',
    );
  }
}
