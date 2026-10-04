import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seva_connect/data/ngo_models.dart';
import 'package:seva_connect/data/volunteer_models.dart';
import 'package:seva_connect/data/volunteer_repository.dart';
import 'package:seva_connect/data/ngo_repository.dart';
import 'package:seva_connect/features/ngo/ngo_providers.dart';
import 'package:seva_connect/features/volunteer/volunteer_providers.dart';
import 'package:seva_connect/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'seva_connect.auth_session': jsonEncode({
        'token': 'volunteer-token',
        'userId': 'volunteer-1',
        'name': 'Maya Volunteer',
        'email': 'maya@example.com',
        'role': 'VOLUNTEER',
      }),
    });
  });

  testWidgets('volunteer can browse, apply, and view application status', (
    tester,
  ) async {
    final repository = _FakeVolunteerRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [volunteerRepositoryProvider.overrideWithValue(repository)],
        child: const SevaConnectApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hello, Maya Volunteer'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
    await tester.tap(find.text('Browse opportunities'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Maya Volunteer'), findsOneWidget);

    await tester.tap(find.text('Browse opportunities'));
    await tester.pumpAndSettle();
    expect(find.text('Park Cleanup'), findsOneWidget);
    expect(find.text('Community Care'), findsOneWidget);
    await tester.tap(find.text('Park Cleanup'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    expect(find.text('Find opportunities'), findsOneWidget);

    await tester.tap(find.text('Park Cleanup'));
    await tester.pumpAndSettle();
    expect(find.text('About this opportunity'), findsOneWidget);
    await tester.tap(find.text('Apply for this opportunity'));
    await tester.pumpAndSettle();
    expect(find.text('You have applied · Pending'), findsOneWidget);

    GoRouter.of(
      tester.element(find.text('You have applied · Pending')),
    ).go('/volunteer/applications');
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Maya Volunteer'), findsOneWidget);

    await tester.tap(find.text('My applications'));
    await tester.pumpAndSettle();
    expect(find.text('Park Cleanup'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
  });

  testWidgets('volunteer routes require an authenticated volunteer', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: SevaConnectApp()));
    await tester.pumpAndSettle();

    GoRouter.of(
      tester.element(find.text('Seva Connect')),
    ).go('/volunteer/applications');
    await tester.pumpAndSettle();

    expect(
      find.text('Please log in to access volunteer opportunities.'),
      findsOneWidget,
    );
    expect(
      find.text('You have not applied to any opportunities yet.'),
      findsNothing,
    );
  });

  testWidgets('NGO sessions cannot open volunteer-only routes', (tester) async {
    SharedPreferences.setMockInitialValues({
      'seva_connect.auth_session': jsonEncode({
        'token': 'ngo-token',
        'userId': 'ngo-1',
        'name': 'Community Care',
        'email': 'care@example.org',
        'role': 'NGO',
      }),
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ngoRepositoryProvider.overrideWithValue(_EmptyNgoRepository()),
        ],
        child: const SevaConnectApp(),
      ),
    );
    await tester.pumpAndSettle();

    GoRouter.of(
      tester.element(find.text('Welcome, Community Care')),
    ).go('/volunteer/opportunities');
    await tester.pumpAndSettle();

    expect(
      find.text('This area is available to volunteers only.'),
      findsOneWidget,
    );
    expect(find.text('Find opportunities'), findsNothing);
  });
}

class _FakeVolunteerRepository implements VolunteerRepository {
  final _opportunity = Opportunity(
    id: 'opportunity-1',
    title: 'Park Cleanup',
    description: 'Help clean the neighborhood park.',
    location: 'City Park',
    date: DateTime.utc(2026, 11, 5, 9),
    status: 'OPEN',
    organization: 'Community Care',
    applicationCount: 4,
  );

  List<VolunteerApplication> _applications = [];

  @override
  Future<List<Opportunity>> getOpenOpportunities({String search = ''}) async {
    if (search.isNotEmpty &&
        !_opportunity.title.toLowerCase().contains(search.toLowerCase()) &&
        !_opportunity.location.toLowerCase().contains(search.toLowerCase()) &&
        !_opportunity.description.toLowerCase().contains(
          search.toLowerCase(),
        )) {
      return [];
    }

    return [_opportunity];
  }

  @override
  Future<Opportunity> getOpportunity(String id) async => _opportunity;

  @override
  Future<List<VolunteerApplication>> getMyApplications() async =>
      List.unmodifiable(_applications);

  @override
  Future<VolunteerApplication> applyToOpportunity(String opportunityId) async {
    final application = VolunteerApplication(
      id: 'application-1',
      status: ApplicationStatus.pending,
      appliedAt: DateTime.utc(2026, 10, 4),
      opportunity: _opportunity,
    );
    _applications = [application];
    return application;
  }
}

class _EmptyNgoRepository implements NgoRepository {
  @override
  Future<List<Opportunity>> getMyOpportunities() async => [];

  @override
  Future<List<NgoApplication>> getApplications(String opportunityId) async =>
      [];

  @override
  Future<Opportunity> createOpportunity({
    required String title,
    required String description,
    required String location,
    required DateTime date,
  }) => throw UnimplementedError();

  @override
  Future<Opportunity> updateOpportunity({
    required String id,
    required String title,
    required String description,
    required String location,
    required DateTime date,
    required String status,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteOpportunity(String id) => throw UnimplementedError();

  @override
  Future<NgoApplication> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
  }) => throw UnimplementedError();
}
