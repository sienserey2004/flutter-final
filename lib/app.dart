// lib/app.dart
import 'package:flutter/material.dart';

import 'auth/auth_controller.dart';
import 'auth/auth_scope.dart';
import 'core/app_theme.dart';
import 'screens/intro/intro_screen.dart';
import 'screens/main/main_shell.dart';
import 'screens/splash_screen.dart';
import 'shopping/cart_controller.dart';
import 'shopping/cart_scope.dart';
import 'shopping/wishlist_controller.dart';
import 'shopping/wishlist_scope.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final AuthController _auth;
  late final CartController _cart;
  late final WishlistController _wishlist;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _wasAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _auth = AuthController();
    _cart = CartController(api: _auth.api);
    _wishlist = WishlistController(api: _auth.api);
    _auth.addListener(_handleAuthChanged);
    _auth.bootstrap();
  }

  void _handleAuthChanged() {
    final isAuthenticated = _auth.isAuthenticated;
    if (isAuthenticated == _wasAuthenticated) return;
    _wasAuthenticated = isAuthenticated;
    if (isAuthenticated) {
      _cart.bootstrap();
      _wishlist.bootstrap();
    } else {
      _cart.reset();
      _wishlist.reset();
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_handleAuthChanged);
    _cart.dispose();
    _wishlist.dispose();
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      controller: _auth,
      child: CartScope(
        controller: _cart,
        child: WishlistScope(
          controller: _wishlist,
          child: MaterialApp(
            title: 'Aurea Skin',
            navigatorKey: _navigatorKey,
            theme: AppTheme.light,
            debugShowCheckedModeBanner: false,
            home: const _AuthGate(),
          ),
        ),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  // Keep the splash visible long enough for its animation to play,
  // even when the session check finishes instantly.
  static const _minSplashDuration = Duration(milliseconds: 2000);
  bool _splashDone = false;
  // null until read from storage; the splash covers that short wait.
  bool? _seenIntro;

  @override
  void initState() {
    super.initState();
    Future.delayed(_minSplashDuration, () {
      if (mounted) setState(() => _splashDone = true);
    });
    IntroScreen.hasBeenSeen().then((seen) {
      if (mounted) setState(() => _seenIntro = seen);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final Widget child = !_splashDone ||
            auth.status == AuthStatus.checking ||
            _seenIntro == null
        ? const SplashScreen(key: ValueKey('splash'))
        : _seenIntro == false
            ? IntroScreen(
                key: const ValueKey('intro'),
                onDone: () => setState(() => _seenIntro = true),
              )
            : const MainShell(key: ValueKey('main'));
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: child,
    );
  }
}
