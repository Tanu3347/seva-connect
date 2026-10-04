import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../data/volunteer_models.dart';
import '../../data/volunteer_repository.dart';

final volunteerRepositoryProvider = Provider<VolunteerRepository>(
  (ref) => VolunteerRepository(ref.watch(dioProvider)),
);

final myApplicationsProvider = FutureProvider<List<VolunteerApplication>>(
  (ref) => ref.watch(volunteerRepositoryProvider).getMyApplications(),
);

final opportunityDetailProvider =
    FutureProvider.family<Opportunity, String>(
      (ref, id) =>
          ref.watch(volunteerRepositoryProvider).getOpportunity(id),
    );

final opportunityListControllerProvider =
    AsyncNotifierProvider<OpportunityListController, List<Opportunity>>(
      OpportunityListController.new,
    );

class OpportunityListController extends AsyncNotifier<List<Opportunity>> {
  var _search = '';
  var _requestId = 0;

  @override
  Future<List<Opportunity>> build() =>
      ref.watch(volunteerRepositoryProvider).getOpenOpportunities();

  Future<void> search(String value) {
    _search = value.trim();
    return _load();
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    final requestId = ++_requestId;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref
          .read(volunteerRepositoryProvider)
          .getOpenOpportunities(search: _search),
    );
    if (requestId == _requestId) state = result;
  }
}

final applicationActionControllerProvider =
    AsyncNotifierProvider<ApplicationActionController, Set<String>>(
      ApplicationActionController.new,
    );

class ApplicationActionController extends AsyncNotifier<Set<String>> {
  final Set<String> _appliedOpportunityIds = {};
  var _loading = false;

  bool hasApplied(String opportunityId) =>
      _appliedOpportunityIds.contains(opportunityId);

  @override
  Future<Set<String>> build() async {
    final applications = await ref.watch(myApplicationsProvider.future);
    _appliedOpportunityIds
      ..clear()
      ..addAll(applications.map((application) => application.opportunity.id));
    return Set.unmodifiable(_appliedOpportunityIds);
  }

  Future<void> apply(String opportunityId) async {
    if (_loading || hasApplied(opportunityId)) return;

    _loading = true;
    state = const AsyncLoading();
    try {
      final application = await ref
          .read(volunteerRepositoryProvider)
          .applyToOpportunity(opportunityId);
      _appliedOpportunityIds.add(application.opportunity.id);
      state = AsyncData(Set.unmodifiable(_appliedOpportunityIds));
      ref.invalidate(myApplicationsProvider);
    } catch (error, stackTrace) {
      if (error is VolunteerApiException &&
          error.message.toLowerCase().contains('already applied')) {
        _appliedOpportunityIds.add(opportunityId);
      }
      state = AsyncError(error, stackTrace);
    } finally {
      _loading = false;
    }
  }

  Future<void> retryLoad() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      ref.invalidate(myApplicationsProvider);
      final applications = await ref.read(myApplicationsProvider.future);
      _appliedOpportunityIds
        ..clear()
        ..addAll(applications.map((application) => application.opportunity.id));
      return Set.unmodifiable(_appliedOpportunityIds);
    });
  }
}
