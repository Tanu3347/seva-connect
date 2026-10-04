import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/profile/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(volunteerProfileProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: const Text('My profile'),
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(volunteerProfileProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (userProfile) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(volunteerProfileProvider),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    child: Text(
                      userProfile.name.isEmpty
                          ? '?'
                          : userProfile.name.characters.first.toUpperCase(),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userProfile.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(userProfile.email),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit profile',
                    onPressed: () => context.push('/volunteer/profile/edit'),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _ProfileSection(
                title: 'About me',
                icon: Icons.person_outline,
                child: Text(
                  _valueOrEmpty(userProfile.bio, 'Add a short introduction.'),
                ),
              ),
              const SizedBox(height: 16),
              _ProfileSection(
                title: 'Location',
                icon: Icons.location_on_outlined,
                child: Text(
                  _valueOrEmpty(userProfile.location, 'Add your location.'),
                ),
              ),
              const SizedBox(height: 16),
              _ProfileSection(
                title: 'Causes I care about',
                icon: Icons.favorite_outline,
                child: userProfile.interests.isEmpty
                    ? const Text('Choose the causes that matter to you.')
                    : Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: userProfile.interests
                            .map((interest) => Chip(label: Text(interest)))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 16),
              _ProfileSection(
                title: 'Skills',
                icon: Icons.handyman_outlined,
                child: userProfile.skills.isEmpty
                    ? const Text('Add skills you would like to contribute.')
                    : Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: userProfile.skills
                            .map((skill) => Chip(label: Text(skill)))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push('/volunteer/profile/edit'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _valueOrEmpty(String? value, String placeholder) =>
    value == null || value.isEmpty ? placeholder : value;

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}
