import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/volunteer_models.dart';
import '../../features/ngo/ngo_providers.dart';

class NgoOpportunityFormScreen extends ConsumerStatefulWidget {
  const NgoOpportunityFormScreen({this.opportunity, super.key});

  final Opportunity? opportunity;

  bool get isEditing => opportunity != null;

  @override
  ConsumerState<NgoOpportunityFormScreen> createState() =>
      _NgoOpportunityFormScreenState();
}

class NgoOpportunityEditLoaderScreen extends ConsumerWidget {
  const NgoOpportunityEditLoaderScreen({
    required this.opportunityId,
    super.key,
  });

  final String opportunityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opportunities = ref.watch(myNgoOpportunitiesProvider);
    return opportunities.when(
      loading: () => Scaffold(
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
          title: const Text('Edit opportunity'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
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
          title: const Text('Edit opportunity'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => ref.invalidate(myNgoOpportunitiesProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (items) {
        Opportunity? opportunity;
        for (final item in items) {
          if (item.id == opportunityId) {
            opportunity = item;
            break;
          }
        }
        if (opportunity == null) {
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
              title: const Text('Edit opportunity'),
            ),
            body: const Center(child: Text('Opportunity not found.')),
          );
        }
        return NgoOpportunityFormScreen(opportunity: opportunity);
      },
    );
  }
}

class _NgoOpportunityFormScreenState
    extends ConsumerState<NgoOpportunityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late DateTime _date;
  late String _status;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final opportunity = widget.opportunity;
    _titleController = TextEditingController(text: opportunity?.title ?? '');
    _descriptionController = TextEditingController(
      text: opportunity?.description ?? '',
    );
    _locationController = TextEditingController(
      text: opportunity?.location ?? '',
    );
    _date =
        opportunity?.date.toLocal() ??
        DateTime.now().add(const Duration(days: 1));
    _status = opportunity?.status ?? 'OPEN';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(now) ? now : _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10),
    );
    if (selected == null) return;
    final selectedTime = TimeOfDay.fromDateTime(_date);
    setState(() {
      _date = DateTime(
        selected.year,
        selected.month,
        selected.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }

  Future<void> _selectTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (selected == null) return;
    setState(() {
      _date = DateTime(
        _date.year,
        _date.month,
        _date.day,
        selected.hour,
        selected.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final controller = ref.read(ngoManagementControllerProvider.notifier);
    try {
      if (widget.opportunity case final opportunity?) {
        await controller.updateOpportunity(
          id: opportunity.id,
          title: _titleController.text,
          description: _descriptionController.text,
          location: _locationController.text,
          date: _date,
          status: _status,
        );
      } else {
        await controller.createOpportunity(
          title: _titleController.text,
          description: _descriptionController.text,
          location: _locationController.text,
          date: _date,
        );
      }
      if (mounted) context.go('/ngo/opportunities');
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
      title: Text(widget.isEditing ? 'Edit opportunity' : 'Create opportunity'),
    ),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  _FormError(message: _error!),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: _requiredField('Enter an opportunity title'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 4,
                  maxLines: 7,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                  ),
                  validator: _requiredField('Enter a description'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: _requiredField('Enter a location'),
                ),
                const SizedBox(height: 20),
                Text(
                  'Date and time',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _submitting ? null : _selectDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(_date),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _submitting ? null : _selectTime,
                        icon: const Icon(Icons.schedule),
                        label: Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatTimeOfDay(TimeOfDay.fromDateTime(_date)),
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.isEditing) ...[
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'OPEN', child: Text('Open')),
                      DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
                    ],
                    onChanged: _submitting
                        ? null
                        : (value) {
                            if (value != null) setState(() => _status = value);
                          },
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.isEditing
                              ? 'Save changes'
                              : 'Create opportunity',
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

String? Function(String?) _requiredField(String message) =>
    (value) => value == null || value.trim().isEmpty ? message : null;

class _FormError extends StatelessWidget {
  const _FormError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
    ),
  );
}
