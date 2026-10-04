import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_session.dart';
import '../data/volunteer_models.dart';
import '../features/auth/auth_controller.dart';
import '../ui/screens/dashboard_screen.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/login_screen.dart';
import '../ui/screens/my_applications_screen.dart';
import '../ui/screens/ngo_applications_screen.dart';
import '../ui/screens/ngo_only_screen.dart';
import '../ui/screens/ngo_opportunities_screen.dart';
import '../ui/screens/ngo_opportunity_form_screen.dart';
import '../ui/screens/opportunity_detail_screen.dart';
import '../ui/screens/opportunity_list_screen.dart';
import '../ui/screens/edit_profile_screen.dart';
import '../ui/screens/profile_screen.dart';
import '../ui/screens/register_screen.dart';
import '../ui/screens/volunteer_only_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final role = state.uri.queryParameters['role'];
          return RegisterScreen(
            initialRole: role == UserRole.ngo.apiValue
                ? UserRole.ngo
                : UserRole.volunteer,
          );
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/volunteer/opportunities',
        builder: (context, state) =>
            const VolunteerOnlyScreen(child: OpportunityListScreen()),
      ),
      GoRoute(
        path: '/volunteer/opportunities/:id',
        builder: (context, state) => VolunteerOnlyScreen(
          child: OpportunityDetailScreen(
            opportunityId: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/volunteer/applications',
        builder: (context, state) =>
            const VolunteerOnlyScreen(child: MyApplicationsScreen()),
      ),
      GoRoute(
        path: '/volunteer/profile',
        builder: (context, state) =>
            const VolunteerOnlyScreen(child: ProfileScreen()),
      ),
      GoRoute(
        path: '/volunteer/profile/edit',
        builder: (context, state) =>
            const VolunteerOnlyScreen(child: EditProfileScreen()),
      ),
      GoRoute(
        path: '/ngo/opportunities',
        builder: (context, state) =>
            const NgoOnlyScreen(child: NgoOpportunitiesScreen()),
      ),
      GoRoute(
        path: '/ngo/opportunities/new',
        builder: (context, state) =>
            const NgoOnlyScreen(child: NgoOpportunityFormScreen()),
      ),
      GoRoute(
        path: '/ngo/opportunities/:id/edit',
        builder: (context, state) => NgoOnlyScreen(
          child: state.extra is Opportunity
              ? NgoOpportunityFormScreen(
                  opportunity: state.extra as Opportunity,
                )
              : NgoOpportunityEditLoaderScreen(
                  opportunityId: state.pathParameters['id']!,
                ),
        ),
      ),
      GoRoute(
        path: '/ngo/opportunities/:id/applications',
        builder: (context, state) => NgoOnlyScreen(
          child: NgoApplicationsScreen(
            opportunityId: state.pathParameters['id']!,
          ),
        ),
      ),
    ],
  );

  ref.listen(authControllerProvider, (_, next) {
    next.whenData((session) {
      if (session != null && router.state.matchedLocation != '/dashboard') {
        router.go('/dashboard');
      } else if (session == null &&
          router.state.matchedLocation == '/dashboard') {
        router.go('/');
      }
    });
  });

  return router;
});
