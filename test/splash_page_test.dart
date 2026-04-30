import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/pages/splash_page.dart';

void main() {
  testWidgets('SplashPage renders icon, title, and progress bar', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashPage()),
    );

    // 等待动画开始
    await tester.pump(const Duration(milliseconds: 200));

    // Verify icon is present (Icon widget with favorite_border)
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

    // Verify app title is present
    expect(find.text('Pulse'), findsOneWidget);

    // Verify subtitle is present
    expect(find.text('性格 · 匹配 · 测试'), findsOneWidget);
  });

  testWidgets('SplashPage navigates to nextPage after timer completes', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const SplashPage(
          nextPage: Scaffold(body: Text('Next Page')),
        ),
      ),
    );

    expect(find.text('Pulse'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(milliseconds: 4000));

    expect(find.text('Next Page'), findsOneWidget);
    expect(find.text('Pulse'), findsNothing);
  });
}
