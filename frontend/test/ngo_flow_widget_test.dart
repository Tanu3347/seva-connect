import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seva_connect/data/ngo_models.dart';
import 'package:seva_connect/data/ngo_repository.dart';
import 'package:seva_connect/data/volunteer_models.dart';
import 'package:seva_connect/features/ngo/ngo_providers.dart';
import 'package:seva_connect/main.dart';

void main() {
  setUp(() => _setNgoSession());

  testWidgets('NGO can create and edit its opportunity', (tester) async {
    final repository = _FakeNgoRepository();
    await _pumpNgoApp(tester, repository);

    expect(find.text('Welcome, Community Care'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
    await tester.tap(find.text('Create an opportunity'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, Community Care'), findsOneWidget);

    await tester.tap(find.text('Create an opportunity'));
    await tester.pumpAndSettle();
    await _enterOpportunity(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Create opportunity'));
    await tester.pumpAndSettle();

    expect(repository.opportunities, hasLength(1));
    expect(find.text('Neighborhood Garden'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    expect(find.text('My opportunities'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Closed').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(repository.opportunities.single.status, 'CLOSED');
    expect(find.text('Closed'), findsOneWidget);
  });

  testWidgets('NGO can delete an opportunity after confirmation', (
    tester,
  ) async {
    final repository = _FakeNgoRepository()..opportunities.add(_opportunity());
    await _pumpNgoApp(tester, repository);

    await tester.tap(find.text('Manage opportunities'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, Community Care'), findsOneWidget);

    await tester.tap(find.text('Manage opportunities'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete opportunity?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repository.opportunities, isEmpty);
    expect(
      find.text('You have not created any opportunities yet.'),
      findsOneWidget,
    );
  });

  testWidgets('NGO accepts a pending applicant and the list refreshes', (
    tester,
  ) async {
    final repository = _FakeNgoRepository()
      ..opportunities.add(_opportunity())
      ..applications.add(_application());
    await _pumpNgoApp(tester, repository);

    await tester.tap(find.text('Manage opportunities'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Applicants'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    expect(find.text('My opportunities'), findsOneWidget);

    await tester.tap(find.text('Applicants'));
    await tester.pumpAndSettle();

    expect(find.text('Maya Volunteer'), findsOneWidget);
    expect(find.text('I enjoy community work.'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(repository.applications.single.status, ApplicationStatus.accepted);
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Accept'), findsNothing);
    expect(repository.applicationFetches, greaterThanOrEqualTo(2));
  });

  testWidgets('volunteers cannot access NGO-only routes', (tester) async {
    SharedPreferences.setMockInitialValues({
      'seva_connect.auth_session': jsonEncode({
        'token': 'volunteer-token',
        'userId': 'volunteer-1',
        'name': 'Maya Volunteer',
        'email': 'maya@example.com',
        'role': 'VOLUNTEER',
      }),
    });
    await tester.pumpWidget(const ProviderScope(child: SevaConnectApp()));
    await tester.pumpAndSettle();

    GoRouter.of(
      tester.element(find.text('Hello, Maya Volunteer')),
    ).go('/ngo/opportunities');
    await tester.pumpAndSettle();

    expect(find.text('This area is available to NGOs only.'), findsOneWidget);
    expect(find.text('My opportunities'), findsNothing);
  });
}

Future<void> _pumpNgoApp(
  WidgetTester tester,
  _FakeNgoRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [ngoRepositoryProvider.overrideWithValue(repository)],
      child: const SevaConnectApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void _setNgoSession() {
  SharedPreferences.setMockInitialValues({
    'seva_connect.auth_session': jsonEncode({
      'token': 'ngo-token',
      'userId': 'ngo-1',
      'name': 'Community Care',
      'email': 'care@example.org',
      'role': 'NGO',
    }),
  });
}

Future<void> _enterOpportunity(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Title'),
    'Neighborhood Garden',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Description'),
    'Help build a community garden.',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Location'),
    'Northside',
  );
}

Opportunity _opportunity({String status = 'OPEN'}) => Opportunity(
  id: 'opportunity-1',
  title: 'Neighborhood Garden',
  description: 'Help build a community garden.',
  location: 'Northside',
  date: DateTime.now().add(const Duration(days: 1)),
  status: status,
  organization: 'Community Care',
  applicationCount: 1,
);

NgoApplication _application({
  ApplicationStatus status = ApplicationStatus.pending,
}) => NgoApplication(
  id: 'application-1',
  status: status,
  appliedAt: DateTime(2026, 10, 1),
  applicant: const NgoApplicant(
    id: 'volunteer-1',
    name: 'Maya Volunteer',
    email: 'maya@example.com',
    bio: 'I enjoy community work.',
    contactInfo: '555-0100',
  ),
  opportunity: _opportunity(),
);

class _FakeNgoRepository implements NgoRepository {
  final List<Opportunity> opportunities = [];
  final List<NgoApplication> applications = [];
  int applicationFetches = 0;

  @override
  Future<List<Opportunity>> getMyOpportunities() async =>
      List.unmodifiable(opportunities);

  @override
  Future<List<NgoApplication>> getApplications(String opportunityId) async {
    applicationFetches++;
    return List.unmodifiable(applications);
  }

  @override
  Future<Opportunity> createOpportunity({
    required String title,
    required String description,
    required String location,
    required DateTime date,
  }) async {
    final opportunity = Opportunity(
      id: 'opportunity-${opportunities.length + 1}',
      title: title,
      description: description,
      location: location,
      date: date,
      status: 'OPEN',
      organization: 'Community Care',
      applicationCount: 0,
    );
    opportunities.add(opportunity);
    return opportunity;
  }

  @override
  Future<Opportunity> updateOpportunity({
    required String id,
    required String title,
    required String description,
    required String location,
    required DateTime date,
    required String status,
  }) async {
    final updated = Opportunity(
      id: id,
      title: title,
      description: description,
      location: location,
      date: date,
      status: status,
      organization: 'Community Care',
      applicationCount: 0,
    );
    opportunities[opportunities.indexWhere((item) => item.id == id)] = updated;
    return updated;
  }

  @override
  Future<void> deleteOpportunity(String id) async {
    opportunities.removeWhere((item) => item.id == id);
  }

  @override
  Future<NgoApplication> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
  }) async {
    final index = applications.indexWhere((item) => item.id == applicationId);
    final updated = _application(status: status);
    applications[index] = updated;
    return updated;
  }
}
