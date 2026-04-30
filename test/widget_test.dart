import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/main.dart';

void main() {
  testWidgets('App starts with SplashPage', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    // 初始帧动画可能还未完成，先 pump 一些时间
    await tester.pump(const Duration(milliseconds: 100));
    
    // Verify SplashPage is shown initially
    expect(find.text('Pulse'), findsOneWidget);
    expect(find.text('性格 · 匹配 · 测试'), findsOneWidget);
  });
}
