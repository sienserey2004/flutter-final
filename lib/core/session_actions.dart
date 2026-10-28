// lib/core/session_actions.dart
import 'package:flutter/material.dart';

import '../auth/auth_scope.dart';
import '../screens/auth/login_screen.dart';
import '../widgets/confirmation_dialog.dart';

Future<bool> requireLogin(BuildContext context) async {
  if (AuthScope.of(context, listen: false).isAuthenticated) return true;
  final loggedIn = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const LoginScreen(),
    ),
  );
  return loggedIn == true;
}

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

  await auth.logout();
}