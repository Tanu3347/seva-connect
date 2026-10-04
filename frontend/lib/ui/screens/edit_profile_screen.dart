import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/volunteer_profile.dart';
import '../../features/profile/profile_providers.dart';

const _availableCauses = [
  'Education',
  'Environment',
  'Community health',
  'Animal welfare',
  'Food security',
  'Elder care',
  'Disability inclusion',
  'Women empowerment',
  'Child welfare',
  'Disaster relief',
  'Arts and culture',
  'Community development',
];

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

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
              context.go('/volunteer/profile');
            }
          },
        ),
        title: const Text('Edit profile'),
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
        data: (userProfile) => _EditProfileForm(profile: userProfile),
      ),
    );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({required this.profile});

  final VolunteerProfile profile;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;
  late final TextEditingController _skillController;
  late final Set<String> _interests;
  late final List<String> _skills;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
    _locationController = TextEditingController(
      text: widget.profile.location ?? '',
    );
    _skillController = TextEditingController();
    _interests = {...widget.profile.interests};
    _skills = [...widget.profile.skills];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  void _addSkills(String value) {
    final entered = value.split(',');
    setState(() {
      for (final item in entered) {
        final skill = item.trim();
        if (skill.isNotEmpty && !_skills.contains(skill)) _skills.add(skill);
      }
      _skillController.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(profileUpdateControllerProvider.notifier)
          .save(
            name: _nameController.text,
            bio: _bioController.text,
            location: _locationController.text,
            interests: _availableCauses
                .where(_interests.contains)
                .toList(growable: false),
            skills: List.unmodifiable(_skills),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully')),
        );
        context.pop();
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_error != null) ...[
          _ProfileError(message: _error!),
          const SizedBox(height: 16),
        ],
        TextFormField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Name',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Name is required'
              : value.trim().length > 100
              ? 'Name must be 100 characters or fewer'
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bioController,
          minLines: 3,
          maxLines: 5,
          maxLength: 1000,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'About me',
            hintText: 'Share a little about yourself',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _locationController,
          textCapitalization: TextCapitalization.words,
          maxLength: 200,
          decoration: const InputDecoration(
            labelText: 'Location',
            prefixIcon: Icon(Icons.location_on_outlined),
            hintText: 'City or area',
          ),
        ),
        const SizedBox(height: 16),
        Text('Causes and interests', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Choose the areas where you would like to help.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _availableCauses
              .map(
                (cause) => FilterChip(
                  label: Text(cause),
                  selected: _interests.contains(cause),
                  onSelected: _saving
                      ? null
                      : (selected) => setState(() {
                          if (selected) {
                            _interests.add(cause);
                          } else {
                            _interests.remove(cause);
                          }
                        }),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        Text('Skills', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Add one or more skills, separated by commas.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _skillController,
          enabled: !_saving,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: _addSkills,
          decoration: InputDecoration(
            labelText: 'Add skills',
            hintText: 'First aid, teaching',
            suffixIcon: IconButton(
              tooltip: 'Add skills',
              onPressed: _saving
                  ? null
                  : () => _addSkills(_skillController.text),
              icon: const Icon(Icons.add),
            ),
          ),
        ),
        if (_skills.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _skills
                .map(
                  (skill) => InputChip(
                    label: Text(skill),
                    onDeleted: _saving
                        ? null
                        : () => setState(() => _skills.remove(skill)),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save profile'),
        ),
      ],
    ),
  );
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message});

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
