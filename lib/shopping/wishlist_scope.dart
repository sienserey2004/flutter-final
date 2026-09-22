import 'package:flutter/widgets.dart';
import 'wishlist_controller.dart';

class WishlistScope extends InheritedNotifier<WishlistController> {
  const WishlistScope({
    super.key,
    required WishlistController controller,
    required super.child,
  }) : super(notifier: controller);

  static WishlistController of(BuildContext context, {bool listen = true}) {
    if (listen) {
      final scope = context.dependOnInheritedWidgetOfExactType<WishlistScope>();
      assert(scope != null, 'WishlistScope not found in widget tree');
      return scope!.notifier!;
    }
    final el = context.getElementForInheritedWidgetOfExactType<WishlistScope>();
    assert(el != null, 'WishlistScope not found in widget tree');
    return (el!.widget as WishlistScope).notifier!;
  }
}