import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/ngo_models.dart';
import '../../data/volunteer_models.dart';
import '../../features/ngo/ngo_providers.dart';

class NgoApplicationsScreen extends ConsumerWidget {
  const NgoApplicationsScreen({required this.opportunityId, super.key});

  final String opportunityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(
      ngoOpportunityApplicationsProvider(opportunityId),
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
              context.go('/ngo/opportunities');
            }
          },
        ),
        title: const Text('Applicants'),
      ),
      body: applications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ApplicantsMessage(
          message: error.toString(),
          actionLabel: 'Try again',
          onPressed: () => ref.invalidate(
            ngoOpportunityApplicationsProvider(opportunityId),
          ),
        ),
        data: (items) => items.isEmpty
            ? const _ApplicantsMessage(
                message: 'No one has applied to this opportunity yet.',
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(
                  ngoOpportunityApplicationsProvider(opportunityId),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _ApplicantCard(
                    application: items[index],
                    opportunityId: opportunityId,
                  ),
                ),
              ),
      ),
    );
  }
}

class _ApplicantCard extends ConsumerStatefulWidget {
  const _ApplicantCard({
    required this.application,
    required this.opportunityId,
  });

  final NgoApplication application;
  final String opportunityId;

  @override
  ConsumerState<_ApplicantCard> createState() => _ApplicantCardState();
}

class _ApplicantCardState extends ConsumerState<_ApplicantCard> {
  bool _updating = false;
  String? _error;

  Future<void> _update(ApplicationStatus status) async {
    setState(() {
      _updating = true;
      _error = null;
    });
    try {
      await ref
          .read(ngoManagementControllerProvider.notifier)
          .updateApplicationStatus(
            applicationId: widget.application.id,
            opportunityId: widget.opportunityId,
            status: status,
          );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final application = widget.application;
    final applicant = application.applicant;
    final color = switch (application.status) {
      ApplicationStatus.pending => Colors.amber.shade800,
      ApplicationStatus.accepted => Colors.green.shade700,
      ApplicationStatus.rejected => Theme.of(context).colorScheme.error,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    applicant.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                _ApplicationStatusChip(
                  status: application.status,
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 6),
            _ApplicantInfo(icon: Icons.email_outlined, text: applicant.email),
            if (applicant.contactInfo != null &&
                applicant.contactInfo!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _ApplicantInfo(
                icon: Icons.contact_phone_outlined,
                text: applicant.contactInfo!,
              ),
            ],
            if (applicant.bio != null && applicant.bio!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(applicant.bio!),
            ],
            const SizedBox(height: 10),
            Text(
              'Applied ${MaterialLocalizations.of(context).formatMediumDate(application.appliedAt.toLocal())}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _ErrorNotice(message: _error!),
            ],
            if (application.status == ApplicationStatus.pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _updating
                          ? null
                          : () => _update(ApplicationStatus.rejected),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _updating
                          ? null
                          : () => _update(ApplicationStatus.accepted),
                      icon: _updating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ApplicationStatusChip extends StatelessWidget {
  const _ApplicationStatusChip({required this.status, required this.color});

  final ApplicationStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(status.label),
    visualDensity: VisualDensity.compact,
    backgroundColor: color.withValues(alpha: 0.10),
    labelStyle: TextStyle(color: color),
  );
}

class _ApplicantInfo extends StatelessWidget {
  const _ApplicantInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 17, color: Theme.of(context).colorScheme.secondary),
      const SizedBox(width: 8),
      Expanded(child: Text(text)),
    ],
  );
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
    ),
  );
}

class _ApplicantsMessage extends StatelessWidget {
  const _ApplicantsMessage({
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null && onPressed != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onPressed,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    ),
  );
}
