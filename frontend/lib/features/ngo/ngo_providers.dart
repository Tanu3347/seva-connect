import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../data/ngo_models.dart';
import '../../data/ngo_repository.dart';
import '../../data/volunteer_models.dart';

final ngoRepositoryProvider = Provider<NgoRepository>(
  (ref) => NgoRepository(ref.watch(dioProvider)),
);

final myNgoOpportunitiesProvider = FutureProvider<List<Opportunity>>(
  (ref) => ref.watch(ngoRepositoryProvider).getMyOpportunities(),
);

final ngoOpportunityApplicationsProvider =
    FutureProvider.family<List<NgoApplication>, String>(
      (ref, id) => ref.watch(ngoRepositoryProvider).getApplications(id),
    );

final ngoManagementControllerProvider =
    AsyncNotifierProvider<NgoManagementController, void>(
      NgoManagementController.new,
    );

class NgoManagementController extends AsyncNotifier<void> {
  var _busy = false;

  @override
  Future<void> build() async {}

  Future<void> createOpportunity({
    required String title,
    required String description,
    required String location,
    required DateTime date,
  }) => _run(() async {
    await ref
        .read(ngoRepositoryProvider)
        .createOpportunity(
          title: title,
          description: description,
          location: location,
          date: date,
        );
    ref.invalidate(myNgoOpportunitiesProvider);
  });

  Future<void> updateOpportunity({
    required String id,
    required String title,
    required String description,
    required String location,
    required DateTime date,
    required String status,
  }) => _run(() async {
    await ref
        .read(ngoRepositoryProvider)
        .updateOpportunity(
          id: id,
          title: title,
          description: description,
          location: location,
          date: date,
          status: status,
        );
    ref.invalidate(myNgoOpportunitiesProvider);
    ref.invalidate(ngoOpportunityApplicationsProvider(id));
  });

  Future<void> deleteOpportunity(String id) => _run(() async {
    await ref.read(ngoRepositoryProvider).deleteOpportunity(id);
    ref.invalidate(myNgoOpportunitiesProvider);
    ref.invalidate(ngoOpportunityApplicationsProvider(id));
  });

  Future<void> updateApplicationStatus({
    required String applicationId,
    required String opportunityId,
    required ApplicationStatus status,
  }) => _run(() async {
    await ref
        .read(ngoRepositoryProvider)
        .updateApplicationStatus(
          applicationId: applicationId,
          status: status,
        );
    ref.invalidate(ngoOpportunityApplicationsProvider(opportunityId));
  });

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    _busy = true;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    state = result;
    _busy = false;
    if (result.hasError) {
      Error.throwWithStackTrace(result.error!, result.stackTrace!);
    }
  }
}
