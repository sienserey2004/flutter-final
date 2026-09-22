import 'package:flutter/material.dart';

import '../widgets/app_logo.dart';
import '../widgets/state_views.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(),
            SizedBox(height: 28),
            LoadingIndicator(message: 'Checking your session…'),
          ],
        ),
      ),
    );
  }
}
