import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/pages/splash_page.dart';

void main() {
  testWidgets('SplashPage renders icon, title, and progress indicator', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashPage()),
    );

    // Verify icon image is present
    expect(find.byType(Image), findsOneWidget);

    // Verify app title is present
    expect(find.text('Pulse'), findsOneWidget);

    // Verify CircularProgressIndicator is present
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
