import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/volunteer_models.dart';
import '../../features/volunteer/volunteer_providers.dart';

class OpportunityDetailScreen extends ConsumerWidget {
  const OpportunityDetailScreen({required this.opportunityId, super.key});

  final String opportunityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunityState = ref.watch(
      opportunityDetailProvider(opportunityId),
    );
    final applicationsState = ref.watch(myApplicationsProvider);
    final actionState = ref.watch(applicationActionControllerProvider);
    final actionController = ref.read(
      applicationActionControllerProvider.notifier,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/volunteer/opportunities');
            }
          },
        ),
        title: const Text('Opportunity details'),
      ),
      body: opportunityState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LoadError(
          message: error.toString(),
          onRetry: () =>
              ref.invalidate(opportunityDetailProvider(opportunityId)),
        ),
        data: (opportunity) => _OpportunityDetails(
          opportunity: opportunity,
          applicationsState: applicationsState,
          actionState: actionState,
          actionController: actionController,
          onApply: () => actionController.apply(opportunityId),
          onRetryApplications: () {
            ref.invalidate(myApplicationsProvider);
            actionController.retryLoad();
          },
        ),
      ),
    );
  }
}

class _OpportunityDetails extends StatelessWidget {
  const _OpportunityDetails({
    required this.opportunity,
    required this.applicationsState,
    required this.actionState,
    required this.actionController,
    required this.onApply,
    required this.onRetryApplications,
  });

  final Opportunity opportunity;
  final AsyncValue<List<VolunteerApplication>> applicationsState;
  final AsyncValue<Set<String>> actionState;
  final ApplicationActionController actionController;
  final VoidCallback onApply;
  final VoidCallback onRetryApplications;

  @override
  Widget build(BuildContext context) {
    VolunteerApplication? existingApplication;
    if (applicationsState.hasValue) {
      for (final application in applicationsState.requireValue) {
        if (application.opportunity.id == opportunity.id) {
          existingApplication = application;
          break;
        }
      }
    }
    final alreadyApplied =
        existingApplication != null ||
        actionController.hasApplied(opportunity.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          opportunity.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          opportunity.organization,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        _DetailLine(
          icon: Icons.location_on_outlined,
          label: opportunity.location,
        ),
        const SizedBox(height: 12),
        _DetailLine(
          icon: Icons.calendar_today_outlined,
          label: _formatDateTime(context, opportunity.date),
        ),
        if (opportunity.applicationCount != null) ...[
          const SizedBox(height: 12),
          _DetailLine(
            icon: Icons.people_outline,
            label: '${opportunity.applicationCount} applicants',
          ),
        ],
        if (opportunity.contactInfo != null &&
            opportunity.contactInfo!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _DetailLine(
            icon: Icons.contact_mail_outlined,
            label: opportunity.contactInfo!,
          ),
        ],
        if (opportunity.organizationBio != null &&
            opportunity.organizationBio!.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'About the organization',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(opportunity.organizationBio!),
        ],
        const SizedBox(height: 24),
        Text(
          'About this opportunity',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(opportunity.description),
        const SizedBox(height: 28),
        if (applicationsState.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (applicationsState.hasError)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InlineNotice(
                message:
                    'Could not check whether you have already applied. '
                    '${applicationsState.error}',
                isError: true,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onRetryApplications,
                child: const Text('Retry'),
              ),
            ],
          )
        else if (actionState.hasError)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InlineNotice(
                message: actionState.error.toString(),
                isError: true,
              ),
              if (alreadyApplied) ...[
                const SizedBox(height: 10),
                if (existingApplication != null)
                  _AppliedStatus(status: existingApplication.status)
                else
                  const _AlreadyAppliedNotice(),
              ] else ...[
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: onApply,
                  child: const Text('Try applying again'),
                ),
              ],
            ],
          )
        else if (existingApplication != null)
          _AppliedStatus(status: existingApplication.status)
        else if (alreadyApplied)
          const _AlreadyAppliedNotice()
        else ...[
          FilledButton.icon(
            onPressed: actionState.isLoading ? null : onApply,
            icon: actionState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(
              actionState.isLoading
                  ? 'Submitting…'
                  : 'Apply for this opportunity',
            ),
          ),
        ],
      ],
    );
  }
}

String _formatDateTime(BuildContext context, DateTime date) {
  final localDate = date.toLocal();
  final formattedDate = MaterialLocalizations.of(
    context,
  ).formatMediumDate(localDate);
  final formattedTime = MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay.fromDateTime(localDate));
  return '$formattedDate at $formattedTime';
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
      const SizedBox(width: 10),
      Expanded(child: Text(label)),
    ],
  );
}

class _AppliedStatus extends StatelessWidget {
  const _AppliedStatus({required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ApplicationStatus.pending => Colors.amber.shade800,
      ApplicationStatus.accepted => Colors.green.shade700,
      ApplicationStatus.rejected => Theme.of(context).colorScheme.error,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'You have applied · ${status.label}',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _AlreadyAppliedNotice extends StatelessWidget {
  const _AlreadyAppliedNotice();

  @override
  Widget build(BuildContext context) => const _InlineNotice(
    message: 'You have already applied for this opportunity.',
  );
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError ? scheme.errorContainer : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError
              ? scheme.onErrorContainer
              : scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
