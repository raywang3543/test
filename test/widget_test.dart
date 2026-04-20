import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/main.dart';

void main() {
  testWidgets('HomePage renders without error', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
