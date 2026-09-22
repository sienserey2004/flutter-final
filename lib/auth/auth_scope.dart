// lib/auth/auth_scope.dart
import 'package:flutter/widgets.dart';

import 'auth_controller.dart';

/// Exposes the single [AuthController] to the whole widget tree.
class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Returns the controller and rebuilds the caller when auth state changes.
  static AuthController of(BuildContext context, {bool listen = true}) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<AuthScope>()
        : context.getInheritedWidgetOfExactType<AuthScope>();
    assert(
      scope != null,
      'AuthScope.of() called with a context that does not contain an AuthScope.',
    );
    return scope!.notifier!;
  }
}
