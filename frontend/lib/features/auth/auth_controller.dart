import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../data/auth_repository.dart';
import '../../data/auth_session.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() => ref.watch(authStorageProvider).readSession();

  Future<void> login({
    required String email,
    required String password,
  }) => _authenticate(
    () => ref
        .read(authRepositoryProvider)
        .login(email: email, password: password),
  );

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) => _authenticate(
    () => ref
        .read(authRepositoryProvider)
        .register(name: name, email: email, password: password, role: role),
  );

  Future<void> _authenticate(Future<AuthSession> Function() request) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await request();
      await ref.read(authStorageProvider).saveSession(session);
      return session;
    });
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authStorageProvider).clearSession();
      return null;
    });
  }
}
