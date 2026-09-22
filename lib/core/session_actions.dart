// lib/core/session_actions.dart
import 'package:flutter/material.dart';

import '../auth/auth_scope.dart';
import '../widgets/confirmation_dialog.dart';

/// Shared logout action used by Profile and Account Settings.
///
/// Logout is an *action*, never a bottom navigation tab.
Future<void> confirmAndLogout(BuildContext context) async {
  final auth = AuthScope.of(context);

  final confirmed = await ConfirmationDialog.show(
    context,
    title: 'Log out',
    message: 'Are you sure you want to log out?',
    confirmLabel: 'Log out',
    destructive: true,
  );

  if (!confirmed) return;

  // Clearing the session flips the root gate to LoginScreen and
  // AppRoot pops every pushed route so back navigation is impossible.
  await auth.logout();
}