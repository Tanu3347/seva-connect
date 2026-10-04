import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seva_connect/main.dart';
import 'package:seva_connect/data/auth_session.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows volunteer and NGO choices on the welcome screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SevaConnectApp()));

    expect(find.text('Seva Connect'), findsOneWidget);
    expect(find.text('I want to volunteer'), findsOneWidget);
    expect(find.text('I represent an NGO'), findsOneWidget);
    expect(find.text('Already have an account? Log in'), findsOneWidget);
  });

  testWidgets('welcome role choice opens registration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: SevaConnectApp()));
    await tester.tap(find.text('I represent an NGO'));
    await tester.pumpAndSettle();

    expect(find.text('Join Seva Connect'), findsOneWidget);
    expect(find.text('Create account'), findsNWidgets(2));
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    final roleSelector = tester.widget<SegmentedButton<UserRole>>(
      find.byType(SegmentedButton<UserRole>),
    );
    expect(roleSelector.selected, {UserRole.ngo});
  });

  testWidgets('login choice opens the login form', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SevaConnectApp()));
    await tester.tap(find.text('Already have an account? Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Log in'), findsNWidgets(2));
  });
}
