import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../data/profile_repository.dart';
import '../../data/volunteer_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(dioProvider)),
);

final volunteerProfileProvider = FutureProvider<VolunteerProfile>(
  (ref) => ref.watch(profileRepositoryProvider).getMyProfile(),
);

final profileUpdateControllerProvider =
    AsyncNotifierProvider<ProfileUpdateController, VolunteerProfile?>(
      ProfileUpdateController.new,
    );

class ProfileUpdateController extends AsyncNotifier<VolunteerProfile?> {
  var _saving = false;

  @override
  Future<VolunteerProfile?> build() async => null;

  Future<void> save({
    required String name,
    required String bio,
    required String location,
    required List<String> interests,
    required List<String> skills,
  }) async {
    if (_saving) return;
    _saving = true;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(profileRepositoryProvider)
          .updateMyProfile(
            name: name,
            bio: bio,
            location: location,
            interests: interests,
            skills: skills,
          ),
    );
    state = result;
    _saving = false;
    if (result.hasError) {
      Error.throwWithStackTrace(result.error!, result.stackTrace!);
    }
    ref.invalidate(volunteerProfileProvider);
  }
}
