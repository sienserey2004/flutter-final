// lib/app.dart
import 'package:flutter/material.dart';

import 'auth/auth_controller.dart';
import 'auth/auth_scope.dart';
import 'core/app_theme.dart';
import 'screens/auth/login_screen.dart';
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
    if (!_auth.isAuthenticated) {
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

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    return switch (auth.status) {
      AuthStatus.checking => const SplashScreen(),
      AuthStatus.authenticated => const MainShell(),
      AuthStatus.unauthenticated => const LoginScreen(),
    };
  }
}
