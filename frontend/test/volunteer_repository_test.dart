import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seva_connect/core/api_client.dart';
import 'package:seva_connect/data/volunteer_models.dart';
import 'package:seva_connect/data/volunteer_repository.dart';

const ngoJson = {
  'id': 'ngo-1',
  'name': 'Community Care',
  'email': 'care@example.org',
  'contactInfo': 'hello@example.org',
  'bio': 'Supporting our community',
};

Map<String, dynamic> opportunityJson({Map<String, dynamic>? ngo = ngoJson}) => {
  'id': 'opportunity-1',
  'title': 'Park Cleanup',
  'description': 'Help clean the neighborhood park.',
  'location': 'City Park',
  'date': '2026-11-05T09:00:00.000Z',
  'status': 'OPEN',
  'ngo': ?ngo,
  '_count': {'applications': 4},
};

Map<String, dynamic> applicationJson({
  String status = 'PENDING',
  Map<String, dynamic>? opportunity,
}) => {
  'id': 'application-1',
  'status': status,
  'appliedAt': '2026-10-01T10:00:00.000Z',
  'opportunity': opportunity ?? opportunityJson(),
};

void main() {
  test('loads open opportunities using existing response fields', () async {
    final requests = <RequestOptions>[];
    final repository = VolunteerRepository(
      _dio((options) {
        requests.add(options);
        return {
          'opportunities': [opportunityJson()],
        };
      }),
    );

    final opportunities = await repository.getOpenOpportunities(search: 'park');

    expect(
      requests.single.uri.toString(),
      '${apiBaseUrl}opportunities?search=park',
    );
    expect(opportunities.single.title, 'Park Cleanup');
    expect(opportunities.single.organization, 'Community Care');
    expect(opportunities.single.applicationCount, 4);
  });

  test(
    'loads opportunity detail and parses application-created shape',
    () async {
      final detailRequests = <RequestOptions>[];
      final repository = VolunteerRepository(
        _dio((options) {
          detailRequests.add(options);
          return {'opportunity': opportunityJson(ngo: null)};
        }),
      );
      final opportunity = await repository.getOpportunity('opportunity-1');
      expect(
        detailRequests.single.uri.toString(),
        '${apiBaseUrl}opportunities/opportunity-1',
      );
      expect(opportunity.organization, 'Organization');

      final applicationRequests = <RequestOptions>[];
      final applyRepository = VolunteerRepository(
        _dio((options) {
          applicationRequests.add(options);
          return {
            'application': applicationJson(
              opportunity: {
                'id': 'opportunity-1',
                'title': 'Park Cleanup',
                'location': 'City Park',
                'date': '2026-11-05T09:00:00.000Z',
                'status': 'OPEN',
              },
            ),
          };
        }),
      );
      final application = await applyRepository.applyToOpportunity(
        'opportunity-1',
      );
      expect(
        applicationRequests.single.uri.toString(),
        '${apiBaseUrl}opportunities/opportunity-1/apply',
      );
      expect(applicationRequests.single.method, 'POST');
      expect(application.status, ApplicationStatus.pending);
      expect(application.opportunity.title, 'Park Cleanup');
    },
  );

  test(
    'loads current application statuses including accepted and rejected',
    () async {
      final requests = <RequestOptions>[];
      final repository = VolunteerRepository(
        _dio((options) {
          requests.add(options);
          return {
            'applications': [
              applicationJson(status: 'PENDING'),
              applicationJson(status: 'ACCEPTED'),
              applicationJson(status: 'REJECTED'),
            ],
          };
        }),
      );

      final applications = await repository.getMyApplications();

      expect(requests.single.uri.toString(), '${apiBaseUrl}applications/my');
      expect(applications.map((application) => application.status).toList(), [
        ApplicationStatus.pending,
        ApplicationStatus.accepted,
        ApplicationStatus.rejected,
      ]);
    },
  );

  test('surfaces the backend duplicate application message', () async {
    final dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 409,
              data: {'error': 'You have already applied for this opportunity'},
            ),
          ),
        ),
      ),
    );
    final repository = VolunteerRepository(dio);

    await expectLater(
      repository.applyToOpportunity('opportunity-1'),
      throwsA(
        isA<VolunteerApiException>().having(
          (error) => error.message,
          'message',
          'You have already applied for this opportunity',
        ),
      ),
    );
  });
}

Dio _dio(Map<String, dynamic> Function(RequestOptions options) respond) {
  final dio = Dio(BaseOptions(baseUrl: apiBaseUrl));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: respond(options),
        ),
      ),
    ),
  );
  return dio;
}
