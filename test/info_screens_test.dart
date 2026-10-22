import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/screens/intro/intro_screen.dart';
import 'package:app/screens/info/about_screen.dart';
import 'package:app/screens/info/help_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(WidgetTester t, Widget w) async {
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: w));
    await t.pumpAndSettle();
  }

  testWidgets('intro pages through and finishes', (t) async {
    var done = false;
    await pump(t, IntroScreen(onDone: () => done = true));
    expect(find.text('Welcome to Aurea Skin'), findsOneWidget);
    await t.tap(find.text('Next'));
    await t.pumpAndSettle();
    await t.tap(find.text('Next'));
    await t.pumpAndSettle();
    expect(find.text('Get started'), findsOneWidget);
    await t.tap(find.text('Get started'));
    await t.pumpAndSettle();
    expect(done, isTrue);
    expect(await IntroScreen.hasBeenSeen(), isTrue);
  });

  testWidgets('about builds', (t) async {
    await pump(t, const AboutScreen());
    expect(find.text('Aurea Skin'), findsOneWidget);
  });

  testWidgets('help expands a question', (t) async {
    await pump(t, const HelpScreen());
    await t.tap(find.text('Which payment methods can I use?'));
    await t.pumpAndSettle();
    expect(find.textContaining('Bakong-supported'), findsOneWidget);
    await t.scrollUntilVisible(find.text('Contact us'), 300);
    expect(find.text('Contact us'), findsOneWidget);
  });
}
