import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/volunteer_models.dart';
import '../../features/ngo/ngo_providers.dart';

class NgoOpportunitiesScreen extends ConsumerWidget {
  const NgoOpportunitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunities = ref.watch(myNgoOpportunitiesProvider);

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
        title: const Text('My opportunities'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/ngo/opportunities/new'),
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
      body: opportunities.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _NgoListMessage(
          icon: Icons.cloud_off_outlined,
          message: error.toString(),
          actionLabel: 'Try again',
          onPressed: () => ref.invalidate(myNgoOpportunitiesProvider),
        ),
        data: (items) => items.isEmpty
            ? _NgoListMessage(
                icon: Icons.event_available_outlined,
                message: 'You have not created any opportunities yet.',
                actionLabel: 'Create an opportunity',
                onPressed: () => context.push('/ngo/opportunities/new'),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(myNgoOpportunitiesProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _NgoOpportunityCard(opportunity: items[index]),
                ),
              ),
      ),
    );
  }
}

class _NgoOpportunityCard extends ConsumerWidget {
  const _NgoOpportunityCard({required this.opportunity});

  final Opportunity opportunity;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  opportunity.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              _StatusChip(status: opportunity.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            opportunity.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _Metadata(icon: Icons.location_on_outlined, label: opportunity.location),
              _Metadata(
                icon: Icons.calendar_today_outlined,
                label: MaterialLocalizations.of(
                  context,
                ).formatMediumDate(opportunity.date.toLocal()),
              ),
              if (opportunity.applicationCount != null)
                _Metadata(
                  icon: Icons.people_outline,
                  label: '${opportunity.applicationCount} applicants',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton.icon(
                onPressed: () => context.push(
                  '/ngo/opportunities/${opportunity.id}/applications',
                ),
                icon: const Icon(Icons.people_outline),
                label: const Text('Applicants'),
              ),
              TextButton.icon(
                onPressed: () => context.push(
                  '/ngo/opportunities/${opportunity.id}/edit',
                  extra: opportunity,
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: () => _confirmDelete(context, ref),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete opportunity?'),
        content: Text(
          '“${opportunity.title}” and its applications will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(ngoManagementControllerProvider.notifier)
          .deleteOpportunity(opportunity.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isOpen = status == 'OPEN';
    final color = isOpen
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outline;
    return Chip(
      label: Text(isOpen ? 'Open' : 'Closed'),
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: 0.10),
      labelStyle: TextStyle(color: color),
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _NgoListMessage extends StatelessWidget {
  const _NgoListMessage({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onPressed, child: Text(actionLabel)),
        ],
      ),
    ),
  );
}
