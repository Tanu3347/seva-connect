import 'package:dio/dio.dart';

import 'ngo_models.dart';
import 'volunteer_models.dart';

class NgoApiException implements Exception {
  const NgoApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NgoRepository {
  const NgoRepository(this._dio);

  final Dio _dio;

  Future<List<Opportunity>> getMyOpportunities() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'opportunities/my',
      );
      final data = jsonObject(response.data, 'opportunity list');
      return jsonObjectList(data['opportunities'], 'opportunity')
          .map(Opportunity.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toApiException(error, 'Could not load your opportunities.');
    } on FormatException catch (error) {
      throw NgoApiException(error.message);
    }
  }

  Future<List<NgoApplication>> getApplications(String opportunityId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'opportunities/$opportunityId/applications',
      );
      final data = jsonObject(response.data, 'application list');
      return jsonObjectList(data['applications'], 'application')
          .map(NgoApplication.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toApiException(error, 'Could not load applicants.');
    } on FormatException catch (error) {
      throw NgoApiException(error.message);
    }
  }

  Future<Opportunity> createOpportunity({
    required String title,
    required String description,
    required String location,
    required DateTime date,
  }) => _saveOpportunity(
    'opportunities',
    {
      'title': title.trim(),
      'description': description.trim(),
      'location': location.trim(),
      'date': date.toUtc().toIso8601String(),
    },
    fallback: 'Could not create opportunity.',
  );

  Future<Opportunity> updateOpportunity({
    required String id,
    required String title,
    required String description,
    required String location,
    required DateTime date,
    required String status,
  }) => _saveOpportunity(
    'opportunities/$id',
    {
      'title': title.trim(),
      'description': description.trim(),
      'location': location.trim(),
      'date': date.toUtc().toIso8601String(),
      'status': status,
    },
    method: 'PUT',
    fallback: 'Could not update opportunity.',
  );

  Future<Opportunity> _saveOpportunity(
    String path,
    Map<String, Object> body, {
    String method = 'POST',
    required String fallback,
  }) async {
    try {
      final response = await _dio.request<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(method: method),
      );
      final data = jsonObject(response.data, 'opportunity');
      return Opportunity.fromJson(
        jsonObject(data['opportunity'], 'opportunity'),
      );
    } on DioException catch (error) {
      throw _toApiException(error, fallback);
    } on FormatException catch (error) {
      throw NgoApiException(error.message);
    }
  }

  Future<void> deleteOpportunity(String id) async {
    try {
      await _dio.delete<void>('opportunities/$id');
    } on DioException catch (error) {
      throw _toApiException(error, 'Could not delete opportunity.');
    }
  }

  Future<NgoApplication> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
  }) async {
    if (status == ApplicationStatus.pending) {
      throw const NgoApiException(
        'Applications can only be accepted or rejected.',
      );
    }
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        'applications/$applicationId/status',
        data: {'status': status.apiValue},
      );
      final data = jsonObject(response.data, 'application');
      return NgoApplication.fromJson(
        jsonObject(data['application'], 'application'),
      );
    } on DioException catch (error) {
      throw _toApiException(error, 'Could not update application status.');
    } on FormatException catch (error) {
      throw NgoApiException(error.message);
    }
  }

  NgoApiException _toApiException(DioException error, String fallback) {
    final body = error.response?.data;
    final message = body is Map<String, dynamic> ? body['error'] : null;
    if (message is String && message.isNotEmpty) {
      return NgoApiException(message);
    }
    if (error.response == null) {
      return const NgoApiException(
        'Could not connect to Seva Connect. Check your connection and API URL.',
      );
    }
    return NgoApiException(
      '$fallback (HTTP ${error.response?.statusCode ?? 'error'}).',
    );
  }
}
