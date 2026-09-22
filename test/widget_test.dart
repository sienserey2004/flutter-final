import 'package:flutter_test/flutter_test.dart';
import 'package:app/app.dart';

void main() {
  testWidgets('shows the authentication splash on startup', (tester) async {
    await tester.pumpWidget(const AppRoot());
    expect(find.text('Checking your session…'), findsOneWidget);
  });
}
