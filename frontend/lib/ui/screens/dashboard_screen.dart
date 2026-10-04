import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/auth_session.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/ngo/ngo_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seva Connect'),
        actions: [
          TextButton.icon(
            onPressed: authState.isLoading
                ? null
                : () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: authState.when(
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error.toString()),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Back to welcome'),
                ),
              ],
            ),
          ),
          data: (session) => session == null
              ? FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Back to welcome'),
                )
              : _DashboardContent(session: session),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    if (session.role == UserRole.ngo) {
      return _NgoDashboardContent(session: session);
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Hello, ${session.name}',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Find a cause you care about and make a difference.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        _DashboardAction(
          icon: Icons.search,
          title: 'Browse opportunities',
          description: 'Explore open volunteering opportunities near you.',
          onTap: () => context.go('/volunteer/opportunities'),
        ),
        const SizedBox(height: 12),
        _DashboardAction(
          icon: Icons.assignment_outlined,
          title: 'My applications',
          description: 'Check the status of your applications.',
          onTap: () => context.go('/volunteer/applications'),
        ),
        const SizedBox(height: 12),
        _DashboardAction(
          icon: Icons.person_outline,
          title: 'My profile',
          description: 'Share your interests, skills, and location.',
          onTap: () => context.go('/volunteer/profile'),
        ),
        const SizedBox(height: 24),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: const Padding(
            padding: EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(Icons.volunteer_activism),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Every act of service helps build a stronger community.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NgoDashboardContent extends ConsumerWidget {
  const _NgoDashboardContent({required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunities = ref.watch(myNgoOpportunitiesProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Welcome, ${session.name}',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text('Manage your volunteering opportunities and applicants.'),
        const SizedBox(height: 20),
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const Icon(Icons.event_available_outlined, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: opportunities.when(
                    loading: () => const Text('Loading your opportunities…'),
                    error: (error, _) => const Text(
                      'Your opportunities could not be loaded.',
                    ),
                    data: (items) => Text(
                      '${items.length} ${items.length == 1 ? 'opportunity' : 'opportunities'}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                if (opportunities.hasError)
                  IconButton(
                    tooltip: 'Retry',
                    onPressed: () => ref.invalidate(myNgoOpportunitiesProvider),
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        _DashboardAction(
          icon: Icons.event_note_outlined,
          title: 'Manage opportunities',
          description: 'Edit listings, check applicants, or close an event.',
          onTap: () => context.go('/ngo/opportunities'),
        ),
        const SizedBox(height: 12),
        _DashboardAction(
          icon: Icons.add_circle_outline,
          title: 'Create an opportunity',
          description: 'Share a new way for volunteers to get involved.',
          onTap: () => context.push('/ngo/opportunities/new'),
        ),
      ],
    );
  }
}

class _DashboardAction extends StatelessWidget {
  const _DashboardAction({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.all(16),
      leading: Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(description),
      ),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}
