# 新手引导功能 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 Pulse App 新增首次启动新手引导，聚光灯遮罩样式，依次高亮「新建测试」卡片、档案图标、事件图标，引导用户了解 3 个核心流程。

**Architecture:** `OnboardingService` 用 SharedPreferences 存储 `onboarding_done`；`OnboardingOverlay` Widget 用 CustomPainter 绘制遮罩+镂空，通过 GlobalKey 定位目标位置；在 `_HomePageState` 中用 Stack 叠加 overlay，拦截导航操作推进步骤。

**Tech Stack:** Flutter, shared_preferences, CustomPainter, GlobalKey/RenderBox

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `lib/services/onboarding_service.dart` | Create | SharedPreferences 读写，判断是否展示引导 |
| `lib/widgets/onboarding_overlay.dart` | Create | 聚光灯遮罩 Widget：CustomPainter + Tooltip + 跳过按钮 |
| `lib/main.dart` | Modify | 添加 GlobalKey、Stack、步骤状态、导航拦截 |
| `test/onboarding_service_test.dart` | Create | OnboardingService 单元测试 |
| `test/onboarding_overlay_test.dart` | Create | OnboardingOverlay Widget 测试 |

---

## Task 1: OnboardingService

**Files:**
- Create: `lib/services/onboarding_service.dart`
- Test: `test/onboarding_service_test.dart`

- [ ] **Step 1: Write failing unit tests**

Create `test/onboarding_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/services/onboarding_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('shouldShow returns true when key is absent', () async {
    expect(await OnboardingService.shouldShow(), isTrue);
  });

  test('shouldShow returns false after markDone', () async {
    await OnboardingService.markDone();
    expect(await OnboardingService.shouldShow(), isFalse);
  });

  test('markDone is idempotent', () async {
    await OnboardingService.markDone();
    await OnboardingService.markDone();
    expect(await OnboardingService.shouldShow(), isFalse);
  });
}
```

- [ ] **Step 2: Run tests — expect failure**

```bash
cd /Users/ray/projects/test
flutter test test/onboarding_service_test.dart
```

Expected: compile error — `onboarding_service.dart` does not exist.

- [ ] **Step 3: Implement OnboardingService**

Create `lib/services/onboarding_service.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _key = 'onboarding_done';

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_key) ?? false);
  }

  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
```

- [ ] **Step 4: Run tests — expect pass**

```bash
flutter test test/onboarding_service_test.dart
```

Expected: All 3 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/services/onboarding_service.dart test/onboarding_service_test.dart
git commit -m "feat: add OnboardingService with SharedPreferences persistence"
```

---

## Task 2: OnboardingOverlay Widget

**Files:**
- Create: `lib/widgets/onboarding_overlay.dart`
- Test: `test/onboarding_overlay_test.dart`

- [ ] **Step 1: Write failing widget tests**

Create `test/onboarding_overlay_test.dart`:

```dart
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
```

- [ ] **Step 2: Run tests — expect failure**

```bash
flutter test test/onboarding_overlay_test.dart
```

Expected: compile error — `onboarding_overlay.dart` does not exist.

- [ ] **Step 3: Create the widgets directory**

```bash
mkdir -p /Users/ray/projects/test/lib/widgets
```

- [ ] **Step 4: Implement OnboardingOverlay**

Create `lib/widgets/onboarding_overlay.dart`:

```dart
import 'package:flutter/material.dart';
import '../theme/y2k_theme.dart';

class OnboardingOverlay extends StatefulWidget {
  final int step;
  final GlobalKey targetKey;
  final String stepLabel;
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool isCircle;
  final VoidCallback onSkip;

  const OnboardingOverlay({
    super.key,
    required this.step,
    required this.targetKey,
    required this.stepLabel,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.isCircle,
    required this.onSkip,
  });

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay> {
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateTargetRect());
  }

  @override
  void didUpdateWidget(OnboardingOverlay old) {
    super.didUpdateWidget(old);
    if (old.step != widget.step) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateTargetRect());
    }
  }

  void _updateTargetRect() {
    final renderBox =
        widget.targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !mounted) return;
    final position = renderBox.localToGlobal(Offset.zero);
    setState(() {
      _targetRect = position & renderBox.size;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_targetRect == null) return const SizedBox.shrink();

    final screen = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final tooltipAbove = _targetRect!.center.dy > screen.height / 2;

    return Stack(
      children: [
        // Spotlight overlay (non-interactive pass-through except skip zone)
        IgnorePointer(
          child: CustomPaint(
            painter: _SpotlightPainter(
              targetRect: _targetRect!,
              isCircle: widget.isCircle,
              accentColor: widget.accentColor,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        // Tooltip
        _buildTooltip(context, screen, tooltipAbove),
        // Skip button
        Positioned(
          top: padding.top + 12,
          right: 16,
          child: GestureDetector(
            onTap: widget.onSkip,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 1.5,
                ),
              ),
              child: const Text(
                '跳过',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTooltip(BuildContext context, Size screen, bool tooltipAbove) {
    const tooltipWidth = 210.0;
    const tooltipHeight = 100.0;

    final centerX = _targetRect!.center.dx;
    final left =
        (centerX - tooltipWidth / 2).clamp(16.0, screen.width - tooltipWidth - 16.0);
    final arrowOffset = (centerX - left - 8).clamp(8.0, tooltipWidth - 24.0);

    final top = tooltipAbove
        ? _targetRect!.top - tooltipHeight - 16
        : _targetRect!.bottom + 12;

    return Positioned(
      left: left,
      top: top,
      width: tooltipWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!tooltipAbove)
            Padding(
              padding: EdgeInsets.only(left: arrowOffset),
              child: CustomPaint(
                size: const Size(16, 9),
                painter: _ArrowPainter(color: widget.accentColor, pointUp: true),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Y2K.ink,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.accentColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.35),
                  offset: const Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.stepLabel,
                  style: Y2K.monoSm.copyWith(color: widget.accentColor),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.title,
                  style: Y2K.title.copyWith(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.subtitle,
                  style: Y2K.bodyMuted.copyWith(
                    color: const Color(0xFFAAAAAA),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (tooltipAbove)
            Padding(
              padding: EdgeInsets.only(left: arrowOffset),
              child: CustomPaint(
                size: const Size(16, 9),
                painter: _ArrowPainter(color: widget.accentColor, pointUp: false),
              ),
            ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final bool isCircle;
  final Color accentColor;

  const _SpotlightPainter({
    required this.targetRect,
    required this.isCircle,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 8.0;
    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final spotRect = targetRect.inflate(pad);
    final cutoutPath = isCircle
        ? (Path()
          ..addOval(Rect.fromCircle(
              center: spotRect.center, radius: spotRect.shortestSide / 2)))
        : (Path()
          ..addRRect(
              RRect.fromRectAndRadius(spotRect, const Radius.circular(20))));

    final overlayPath =
        Path.combine(PathOperation.difference, fullPath, cutoutPath);

    canvas.drawPath(
      overlayPath,
      Paint()..color = const Color(0xB30E0E12),
    );

    // Glow ring
    canvas.drawPath(
      cutoutPath,
      Paint()
        ..color = accentColor.withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.targetRect != targetRect ||
      old.isCircle != isCircle ||
      old.accentColor != accentColor;
}

class _ArrowPainter extends CustomPainter {
  final Color color;
  final bool pointUp;

  const _ArrowPainter({required this.color, required this.pointUp});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointUp) {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height);
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.color != color || old.pointUp != pointUp;
}
```

- [ ] **Step 5: Run tests — expect pass**

```bash
flutter test test/onboarding_overlay_test.dart
```

Expected: Both tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/onboarding_overlay.dart test/onboarding_overlay_test.dart
git commit -m "feat: add OnboardingOverlay with spotlight CustomPainter and tooltip"
```

---

## Task 3: Wire up in main.dart

**Files:**
- Modify: `lib/main.dart`

This task has no isolated unit test (integration is verified by running the app). The existing tests still pass after the changes.

- [ ] **Step 1: Add imports and GlobalKeys**

At the top of `lib/main.dart`, add these imports after the existing ones:

```dart
import 'services/onboarding_service.dart';
import 'widgets/onboarding_overlay.dart';
```

In `_HomePageState`, add GlobalKeys and onboarding step state alongside the existing fields:

```dart
class _HomePageState extends State<HomePage> {
  bool _hasOwnSurvey = false;
  String _serverUrl = '';
  int _onboardingStep = 0; // 0 = hidden, 1-3 = active step

  final GlobalKey _createCardKey = GlobalKey();
  final GlobalKey _profileIconKey = GlobalKey();
  final GlobalKey _eventIconKey = GlobalKey();
```

- [ ] **Step 2: Check onboarding in _initApp**

In `_initApp()`, append the onboarding check after `_checkUserSurvey()`:

```dart
Future<void> _initApp() async {
  String? url = await ServerConfig.getBaseUrl();
  if (url == null || url.isEmpty) {
    await ServerConfig.setBaseUrl(ServerConfig.defaultUrl);
    url = ServerConfig.defaultUrl;
  }
  setState(() => _serverUrl = url!);
  await _checkUserSurvey();

  // Onboarding: check once, mark done immediately so exit doesn't re-trigger
  if (await OnboardingService.shouldShow()) {
    await OnboardingService.markDone();
    if (mounted) setState(() => _onboardingStep = 1);
  }
}
```

- [ ] **Step 3: Add _skipOnboarding and _advanceOnboarding helpers**

Add these two methods to `_HomePageState`:

```dart
void _advanceOnboarding(int fromStep) {
  if (_onboardingStep != fromStep) return;
  setState(() {
    _onboardingStep = fromStep + 1 > 3 ? 0 : fromStep + 1;
  });
}

void _skipOnboarding() {
  setState(() => _onboardingStep = 0);
}
```

- [ ] **Step 4: Update _goToCreate to advance step 1**

Replace the existing `_goToCreate`:

```dart
void _goToCreate() {
  _advanceOnboarding(1);
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CreateSurveyPage()),
  ).then((_) => _checkUserSurvey());
}
```

- [ ] **Step 5: Add key parameter to _iconChip and assign GlobalKeys**

Change `_iconChip` to accept an optional key:

```dart
Widget _iconChip(IconData icon, VoidCallback onTap, {Key? key}) {
  return Material(
    key: key,
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Y2K.card,
          shape: BoxShape.circle,
          border: Border.all(color: Y2K.ink, width: 1.5),
        ),
        child: Icon(icon, size: 18, color: Y2K.ink),
      ),
    ),
  );
}
```

In `_buildTopBar()`, update the event and person icon calls to advance onboarding and pass keys:

```dart
Widget _buildTopBar() {
  return Row(
    children: [
      const Y2KChip(label: 'v2.6 · BETA'),
      const Spacer(),
      _iconChip(Icons.event_note_outlined, () {
        _advanceOnboarding(3);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EventPage()),
        );
      }, key: _eventIconKey),
      const SizedBox(width: 8),
      _iconChip(Icons.people_outline_rounded, () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserListPage()),
        );
      }),
      const SizedBox(width: 8),
      _iconChip(Icons.person_outline_rounded, () {
        _advanceOnboarding(2);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserProfilePage()),
        );
      }, key: _profileIconKey),
      const SizedBox(width: 8),
      _iconChip(Icons.dns_outlined, () => _showServerConfigDialog()),
    ],
  );
}
```

- [ ] **Step 6: Add GlobalKey to the 新建测试 FeatureCard**

In `_FeatureCard`'s constructor, add `super.key`:

```dart
const _FeatureCard({
  super.key,
  required this.index,
  required this.title,
  required this.description,
  required this.accent,
  required this.icon,
  required this.onTap,
  this.foreground = Y2K.ink,
});
```

In `_HomePageState.build()`, pass `_createCardKey` to the first FeatureCard:

```dart
_FeatureCard(
  key: _createCardKey,
  index: '01',
  title: '新建测试',
  description: '创建性格匹配题目，设置选项与分数',
  accent: Y2K.lime,
  icon: Icons.edit_note_rounded,
  onTap: _goToCreate,
),
```

- [ ] **Step 7: Wrap build output in Stack with OnboardingOverlay**

Replace the `return Y2KScaffold(...)` block in `build()` with a Stack version. The scaffold content stays exactly the same; just wrap it:

```dart
@override
Widget build(BuildContext context) {
  final scaffold = Y2KScaffold(
    dots: true,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(),
            const SizedBox(height: 28),
            _buildHero(),
            const SizedBox(height: 20),
            _buildStatBadge(),
            const SizedBox(height: 20),
            _FeatureCard(
              key: _createCardKey,
              index: '01',
              title: '新建测试',
              description: '创建性格匹配题目，设置选项与分数',
              accent: Y2K.lime,
              icon: Icons.edit_note_rounded,
              onTap: _goToCreate,
            ),
            const SizedBox(height: 12),
            _FeatureCard(
              index: '02',
              title: '开始测试',
              description: '选择测试题目，测试你们的匹配程度',
              accent: Y2K.blue,
              foreground: Colors.white,
              icon: Icons.play_arrow_rounded,
              onTap: _goToTestList,
            ),
            if (_hasOwnSurvey) ...[
              const SizedBox(height: 12),
              _FeatureCard(
                index: '03',
                title: '删除测试',
                description: '移除您创建的性格匹配题目',
                accent: Y2K.danger,
                foreground: Colors.white,
                icon: Icons.delete_outline_rounded,
                onTap: _deleteOwnSurvey,
              ),
            ],
            const SizedBox(height: 26),
            const Y2KMarquee(
              text: 'MATCH  ✦  CONNECT  ✦  DISCOVER  ✦  Y2K  ✦  2026',
            ),
          ],
        ),
      ),
    ),
  );

  if (_onboardingStep == 0) return scaffold;

  // Step → (targetKey, accentColor, isCircle, stepLabel, title, subtitle)
  final steps = {
    1: (
      _createCardKey,
      Y2K.lime,
      false,
      'STEP 1 / 3 · 新建测试',
      '出一道属于你的题',
      '点击进入 → AI 生成题目 → 保存发布',
    ),
    2: (
      _profileIconKey,
      Y2K.pink,
      true,
      'STEP 2 / 3 · 你的档案',
      '完善你的个人信息',
      '进入档案 → 编辑资料 → 保存',
    ),
    3: (
      _eventIconKey,
      Y2K.blue,
      true,
      'STEP 3 / 3 · 答题记录',
      '查看答题记录',
      '查看别人对你测试的结果',
    ),
  };

  final s = steps[_onboardingStep]!;

  return Stack(
    children: [
      scaffold,
      OnboardingOverlay(
        step: _onboardingStep,
        targetKey: s.$1,
        accentColor: s.$2,
        isCircle: s.$3,
        stepLabel: s.$4,
        title: s.$5,
        subtitle: s.$6,
        onSkip: _skipOnboarding,
      ),
    ],
  );
}
```

- [ ] **Step 8: Run all tests**

```bash
flutter test
```

Expected: All tests pass (onboarding_service_test + onboarding_overlay_test + any existing tests).

- [ ] **Step 9: Analyze for issues**

```bash
flutter analyze
```

Expected: No errors. Fix any warnings about deprecated APIs or null safety before continuing.

- [ ] **Step 10: Commit**

```bash
git add lib/main.dart
git commit -m "feat: wire up onboarding spotlight overlay in HomePage"
```

---

## Self-Review

**Spec coverage:**
- ✅ 首次启动展示（`shouldShow()` + `markDone()` in `_initApp`）
- ✅ 3步引导流程（step 1→2→3，每步高亮对应目标）
- ✅ 点击即完成（`_advanceOnboarding` 在导航前调用）
- ✅ 跳过按钮（`_skipOnboarding`）
- ✅ 退出不再展示（`markDone()` 在引导开始时写入）
- ✅ Y2K 风格遮罩 + 光晕 + 深色 Tooltip

**Type consistency:**
- `_advanceOnboarding(int fromStep)` — called as `_advanceOnboarding(1/2/3)` — ✅
- `OnboardingOverlay` props — defined in Task 2, used exactly in Task 3 — ✅
- `_createCardKey` / `_profileIconKey` / `_eventIconKey` — GlobalKey, assigned in Task 3 Step 1, used in Steps 5/6/7 — ✅
- Record fields `s.$1` through `s.$6` — Dart record positional fields, order matches tuple literal — ✅
