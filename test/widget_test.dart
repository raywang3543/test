import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/main.dart';

void main() {
  testWidgets('App starts with SplashPage', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    // Verify SplashPage is shown initially
    expect(find.text('Pulse'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
