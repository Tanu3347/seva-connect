import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/volunteer_models.dart';
import '../../features/volunteer/volunteer_providers.dart';

class OpportunityListScreen extends ConsumerStatefulWidget {
  const OpportunityListScreen({super.key});

  @override
  ConsumerState<OpportunityListScreen> createState() =>
      _OpportunityListScreenState();
}

class _OpportunityListScreenState extends ConsumerState<OpportunityListScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _search(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => ref
          .read(opportunityListControllerProvider.notifier)
          .search(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final opportunities = ref.watch(opportunityListControllerProvider);

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
        title: const Text('Find opportunities'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by title, description, or location',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
          Expanded(
            child: opportunities.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _MessageState(
                icon: Icons.cloud_off_outlined,
                message: error.toString(),
                buttonLabel: 'Try again',
                onPressed: () => ref
                    .read(opportunityListControllerProvider.notifier)
                    .refresh(),
              ),
              data: (items) => items.isEmpty
                  ? _MessageState(
                      icon: Icons.search_off,
                      message: _searchController.text.trim().isEmpty
                          ? 'There are no open opportunities right now.'
                          : 'No opportunities match your search.',
                      buttonLabel: _searchController.text.trim().isEmpty
                          ? 'Refresh'
                          : 'Clear search',
                      onPressed: () {
                        if (_searchController.text.isNotEmpty) {
                          _searchController.clear();
                          _search('');
                          setState(() {});
                        } else {
                          ref
                              .read(opportunityListControllerProvider.notifier)
                              .refresh();
                        }
                      },
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(opportunityListControllerProvider.notifier)
                          .refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _OpportunityCard(opportunity: items[index]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({required this.opportunity});

  final Opportunity opportunity;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => context.push('/volunteer/opportunities/${opportunity.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              opportunity.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              opportunity.organization,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 10),
            Text(
              opportunity.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            _OpportunityMetadata(
              location: opportunity.location,
              date: opportunity.date,
              applicationCount: opportunity.applicationCount,
            ),
          ],
        ),
      ),
    ),
  );
}

class _OpportunityMetadata extends StatelessWidget {
  const _OpportunityMetadata({
    required this.location,
    required this.date,
    this.applicationCount,
  });

  final String location;
  final DateTime date;
  final int? applicationCount;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    runSpacing: 8,
    children: [
      _Metadata(icon: Icons.location_on_outlined, label: location),
      _Metadata(
        icon: Icons.calendar_today_outlined,
        label: MaterialLocalizations.of(context).formatMediumDate(date.toLocal()),
      ),
      if (applicationCount != null)
        _Metadata(
          icon: Icons.people_outline,
          label: '$applicationCount applicants',
        ),
    ],
  );
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onPressed, child: Text(buttonLabel)),
        ],
      ),
    ),
  );
}
