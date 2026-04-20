import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test/widgets/onboarding_overlay.dart';

void main() {
  testWidgets('skip button calls onSkip', (tester) async {
    bool skipped = false;
    final targetKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              // Target widget the overlay will highlight
              Container(key: targetKey, width: 200, height: 60, color: Colors.blue),
              OnboardingOverlay(
                step: 1,
                targetKey: targetKey,
                stepLabel: 'STEP 1 / 3',
                title: '新建测试',
                subtitle: '点击进入 → AI 生成 → 保存发布',
                accentColor: const Color(0xFFC6FF3D),
                isCircle: false,
                onSkip: () => skipped = true,
              ),
            ],
          ),
        ),
      ),
    );

    // Let post-frame callback run
    await tester.pump();

    expect(find.text('跳过'), findsOneWidget);
    await tester.tap(find.text('跳过'));
    expect(skipped, isTrue);
  });

  testWidgets('tooltip shows title and subtitle', (tester) async {
    final targetKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Container(key: targetKey, width: 200, height: 60, color: Colors.blue),
              OnboardingOverlay(
                step: 1,
                targetKey: targetKey,
                stepLabel: 'STEP 1 / 3',
                title: '新建测试',
                subtitle: '点击进入 → AI 生成 → 保存发布',
                accentColor: const Color(0xFFC6FF3D),
                isCircle: false,
                onSkip: () {},
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('新建测试'), findsOneWidget);
    expect(find.text('点击进入 → AI 生成 → 保存发布'), findsOneWidget);
    expect(find.text('STEP 1 / 3'), findsOneWidget);
  });
}
