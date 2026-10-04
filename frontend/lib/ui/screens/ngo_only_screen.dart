import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/auth_session.dart';
import '../../features/auth/auth_controller.dart';

class NgoOnlyScreen extends ConsumerWidget {
  const NgoOnlyScreen({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return auth.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: _NgoAccessMessage(
          message: 'Could not restore your session: $error',
          actionLabel: 'Retry',
          onPressed: () => ref.invalidate(authControllerProvider),
        ),
      ),
      data: (session) {
        if (session == null) {
          return Scaffold(
            body: _NgoAccessMessage(
              message: 'Please log in to manage NGO opportunities.',
              actionLabel: 'Log in',
              onPressed: () => context.go('/login'),
            ),
          );
        }
        if (session.role != UserRole.ngo) {
          return Scaffold(
            body: _NgoAccessMessage(
              message: 'This area is available to NGOs only.',
              actionLabel: 'Back to dashboard',
              onPressed: () => context.go('/dashboard'),
            ),
          );
        }
        return child;
      },
    );
  }
}

class _NgoAccessMessage extends StatelessWidget {
  const _NgoAccessMessage({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onPressed, child: Text(actionLabel)),
        ],
      ),
    ),
  );
}
