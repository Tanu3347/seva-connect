import 'package:dio/dio.dart';

import 'volunteer_models.dart';

class VolunteerApiException implements Exception {
  const VolunteerApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VolunteerRepository {
  const VolunteerRepository(this._dio);

  final Dio _dio;

  Future<List<Opportunity>> getOpenOpportunities({String search = ''}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'opportunities',
        queryParameters: {
          if (search.trim().isNotEmpty) 'search': search.trim(),
        },
      );
      final data = jsonObject(response.data, 'opportunity list');
      return jsonObjectList(data['opportunities'], 'opportunity')
          .map(Opportunity.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toApiException(error, 'Could not load opportunities.');
    } on FormatException catch (error) {
      throw VolunteerApiException(error.message);
    }
  }

  Future<Opportunity> getOpportunity(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'opportunities/$id',
      );
      final data = jsonObject(response.data, 'opportunity');
      return Opportunity.fromJson(jsonObject(data['opportunity'], 'opportunity'));
    } on DioException catch (error) {
      throw _toApiException(error, 'Could not load this opportunity.');
    } on FormatException catch (error) {
      throw VolunteerApiException(error.message);
    }
  }

  Future<List<VolunteerApplication>> getMyApplications() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'applications/my',
      );
      final data = jsonObject(response.data, 'application list');
      return jsonObjectList(data['applications'], 'application')
          .map(VolunteerApplication.fromJson)
          .toList(growable: false);
    } on DioException catch (error) {
      throw _toApiException(error, 'Could not load your applications.');
    } on FormatException catch (error) {
      throw VolunteerApiException(error.message);
    }
  }

  Future<VolunteerApplication> applyToOpportunity(String opportunityId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'opportunities/$opportunityId/apply',
      );
      final data = jsonObject(response.data, 'application');
      return VolunteerApplication.fromJson(
        jsonObject(data['application'], 'application'),
      );
    } on DioException catch (error) {
      throw _toApiException(error, 'Could not submit your application.');
    } on FormatException catch (error) {
      throw VolunteerApiException(error.message);
    }
  }

  VolunteerApiException _toApiException(
    DioException error,
    String fallback,
  ) {
    final body = error.response?.data;
    final message = body is Map<String, dynamic> ? body['error'] : null;
    if (message is String && message.isNotEmpty) {
      return VolunteerApiException(message);
    }
    if (error.response == null) {
      return const VolunteerApiException(
        'Could not connect to Seva Connect. Check your connection and API URL.',
      );
    }
    return VolunteerApiException(
      '$fallback (HTTP ${error.response?.statusCode ?? 'error'}).',
    );
  }
}
