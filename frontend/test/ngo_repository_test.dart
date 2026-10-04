import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seva_connect/core/api_client.dart';
import 'package:seva_connect/data/ngo_repository.dart';
import 'package:seva_connect/data/volunteer_models.dart';

Map<String, dynamic> opportunityJson({
  String status = 'OPEN',
  Map<String, dynamic>? count = const {'applications': 2},
}) => {
  'id': 'opportunity-1',
  'title': 'Park Cleanup',
  'description': 'Help clean the park.',
  'location': 'City Park',
  'date': '2026-11-05T09:00:00.000Z',
  'status': status,
  '_count': ?count,
};

Map<String, dynamic> applicationJson({String status = 'PENDING'}) => {
  'id': 'application-1',
  'status': status,
  'appliedAt': '2026-10-01T10:00:00.000Z',
  'volunteer': {
    'id': 'volunteer-1',
    'name': 'Maya Volunteer',
    'email': 'maya@example.com',
    'bio': 'I enjoy community work.',
    'contactInfo': '555-0100',
  },
  'opportunity': {
    'id': 'opportunity-1',
    'title': 'Park Cleanup',
    'location': 'City Park',
    'date': '2026-11-05T09:00:00.000Z',
    'status': 'OPEN',
  },
};

void main() {
  test('loads NGO-owned opportunities from the protected my route', () async {
    final requests = <RequestOptions>[];
    final repository = NgoRepository(
      _dio(
        requests,
        (_) => {
          'opportunities': [opportunityJson()],
        },
      ),
    );

    final opportunities = await repository.getMyOpportunities();

    expect(requests.single.uri.toString(), '${apiBaseUrl}opportunities/my');
    expect(opportunities.single.title, 'Park Cleanup');
    expect(opportunities.single.applicationCount, 2);
  });

  test(
    'creates opportunity using the existing create request contract',
    () async {
      final requests = <RequestOptions>[];
      final repository = NgoRepository(
        _dio(requests, (_) => {'opportunity': opportunityJson(count: null)}),
      );
      final date = DateTime.utc(2026, 11, 5, 9);

      await repository.createOpportunity(
        title: 'Park Cleanup',
        description: 'Help clean the park.',
        location: 'City Park',
        date: date,
      );

      final request = requests.single;
      expect(request.uri.toString(), '${apiBaseUrl}opportunities');
      expect(request.method, 'POST');
      expect(request.data, {
        'title': 'Park Cleanup',
        'description': 'Help clean the park.',
        'location': 'City Park',
        'date': '2026-11-05T09:00:00.000Z',
      });
    },
  );

  test('updates and deletes opportunity using existing endpoints', () async {
    final requests = <RequestOptions>[];
    final repository = NgoRepository(
      _dio(requests, (_) => {'opportunity': opportunityJson(status: 'CLOSED')}),
    );

    await repository.updateOpportunity(
      id: 'opportunity-1',
      title: 'Park Cleanup Updated',
      description: 'Updated description',
      location: 'City Park',
      date: DateTime.utc(2026, 11, 5, 9),
      status: 'CLOSED',
    );
    await repository.deleteOpportunity('opportunity-1');

    expect(
      requests[0].uri.toString(),
      '${apiBaseUrl}opportunities/opportunity-1',
    );
    expect(requests[0].method, 'PUT');
    expect(requests[0].data['status'], 'CLOSED');
    expect(
      requests[1].uri.toString(),
      '${apiBaseUrl}opportunities/opportunity-1',
    );
    expect(requests[1].method, 'DELETE');
  });

  test('loads applicants with volunteer info and all statuses', () async {
    final requests = <RequestOptions>[];
    final repository = NgoRepository(
      _dio(
        requests,
        (_) => {
          'applications': [
            applicationJson(status: 'PENDING'),
            applicationJson(status: 'ACCEPTED'),
            applicationJson(status: 'REJECTED'),
          ],
        },
      ),
    );

    final applications = await repository.getApplications('opportunity-1');

    expect(
      requests.single.uri.toString(),
      '${apiBaseUrl}opportunities/opportunity-1/applications',
    );
    expect(applications.first.applicant.name, 'Maya Volunteer');
    expect(applications.first.applicant.bio, 'I enjoy community work.');
    expect(applications.map((item) => item.status).toList(), [
      ApplicationStatus.pending,
      ApplicationStatus.accepted,
      ApplicationStatus.rejected,
    ]);
  });

  test('accepts or rejects by patching existing status endpoint', () async {
    final requests = <RequestOptions>[];
    final repository = NgoRepository(
      _dio(
        requests,
        (_) => {'application': applicationJson(status: 'ACCEPTED')},
      ),
    );

    final application = await repository.updateApplicationStatus(
      applicationId: 'application-1',
      status: ApplicationStatus.accepted,
    );

    expect(
      requests.single.uri.toString(),
      '${apiBaseUrl}applications/application-1/status',
    );
    expect(requests.single.method, 'PATCH');
    expect(requests.single.data, {'status': 'ACCEPTED'});
    expect(application.status, ApplicationStatus.accepted);
  });

  test('rejects an applicant using the same status endpoint', () async {
    final requests = <RequestOptions>[];
    final repository = NgoRepository(
      _dio(requests, (_) => {'application': applicationJson(status: 'REJECTED')}),
    );

    final application = await repository.updateApplicationStatus(
      applicationId: 'application-1',
      status: ApplicationStatus.rejected,
    );

    expect(requests.single.method, 'PATCH');
    expect(requests.single.data, {'status': 'REJECTED'});
    expect(application.status, ApplicationStatus.rejected);
  });

  test('surfaces backend authorization errors', () async {
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 403,
              data: {'error': 'Forbidden: You do not own this opportunity'},
            ),
          ),
        ),
      ),
    );
    final repository = NgoRepository(dio);

    await expectLater(
      repository.deleteOpportunity('opportunity-1'),
      throwsA(
        isA<NgoApiException>().having(
          (error) => error.message,
          'message',
          'Forbidden: You do not own this opportunity',
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
            data: options.method == 'DELETE' ? null : respond(options),
          ),
        );
      },
    ),
  );
  return dio;
}
