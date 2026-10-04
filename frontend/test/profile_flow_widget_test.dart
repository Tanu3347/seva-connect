import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seva_connect/data/profile_repository.dart';
import 'package:seva_connect/data/volunteer_profile.dart';
import 'package:seva_connect/features/profile/profile_providers.dart';
import 'package:seva_connect/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'seva_connect.auth_session': jsonEncode({
        'token': 'volunteer-token',
        'userId': 'volunteer-1',
        'name': 'Sam Volunteer',
        'email': 'sam@example.com',
        'role': 'VOLUNTEER',
      }),
    });
  });

  testWidgets('volunteer loads and saves profile with selected causes/skills', (
    tester,
  ) async {
    final repository = _FakeProfileRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileRepositoryProvider.overrideWithValue(repository)],
        child: const SevaConnectApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
    GoRouter.of(
      tester.element(find.text('Hello, Sam Volunteer')),
    ).go('/volunteer/profile');
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Sam Volunteer'), findsOneWidget);

    GoRouter.of(
      tester.element(find.text('Hello, Sam Volunteer')),
    ).go('/volunteer/profile');
    await tester.pumpAndSettle();
    expect(find.text('Sam Volunteer'), findsOneWidget);
    expect(find.text('Add a short introduction.'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit profile'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    expect(find.text('My profile'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit profile'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'I care about local communities.',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'Riverside');
    await tester.tap(find.text('Environment'));
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'First aid, Teaching');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(repository.savedProfile.bio, 'I care about local communities.');
    expect(repository.savedProfile.location, 'Riverside');
    expect(repository.savedProfile.interests, contains('Environment'));
    expect(
      repository.savedProfile.skills,
      containsAll(['First aid', 'Teaching']),
    );
    expect(find.text('I care about local communities.'), findsOneWidget);
    expect(find.text('Riverside'), findsOneWidget);
    expect(find.text('First aid'), findsOneWidget);
    expect(find.text('Profile saved successfully'), findsOneWidget);
  });
}

class _FakeProfileRepository implements ProfileRepository {
  VolunteerProfile savedProfile = const VolunteerProfile(
    id: 'volunteer-1',
    email: 'sam@example.com',
    name: 'Sam Volunteer',
  );

  @override
  Future<VolunteerProfile> getMyProfile() async => savedProfile;

  @override
  Future<VolunteerProfile> updateMyProfile({
    required String name,
    required String bio,
    required String location,
    required List<String> interests,
    required List<String> skills,
  }) async {
    savedProfile = VolunteerProfile(
      id: 'volunteer-1',
      email: 'sam@example.com',
      name: name,
      bio: bio,
      location: location,
      interests: List.unmodifiable(interests),
      skills: List.unmodifiable(skills),
    );
    return savedProfile;
  }
}
