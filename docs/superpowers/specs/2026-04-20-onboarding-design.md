# 新手引导功能设计文档

**日期：** 2026-04-20  
**状态：** 已批准

---

## 概述

为 Pulse App 新增首次启动新手引导，采用聚光灯遮罩（Spotlight Overlay）样式，引导用户依次了解 3 个核心流程。

---

## 触发与关闭条件

- **触发：** 首次安装后第一次进入 App（`onboarding_done` 不存在）
- **关闭条件（任一触发即永久关闭）：**
  - 用户完成全部 3 个步骤
  - 用户点击「跳过」按钮
  - 用户退出 App（进程结束时不重新展示）
- **持久化：** `SharedPreferences` 存储 `onboarding_done`（bool），任意关闭条件触发后写入 `true`，下次启动跳过引导
- **步骤进度不持久化：** 中途退出后不继续，下次启动也不再展示

---

## 3 步引导流程

| 步骤 | 高亮目标 | Tooltip 内容 | 完成判定 |
|------|---------|-------------|---------|
| 1 | 首页「新建测试」Feature Card | 出一道属于你的题：点击进入 → AI 生成 → 保存发布 | 用户点击该卡片（进入 CreateSurveyPage） |
| 2 | 顶栏「档案」图标（person icon） | 完善你的个人信息：进入档案 → 编辑资料 → 保存 | 用户点击该图标（进入 UserProfilePage） |
| 3 | 顶栏「事件」图标（event_note icon） | 查看答题记录：查看别人对你测试的结果 | 用户点击该图标（进入 EventPage） |

---

## 视觉设计

- **遮罩：** `rgba(14,14,18,0.7)` 全屏覆盖，使用 `CustomPaint` 在目标区域镂空
- **镂空形状：** 圆角矩形（Feature Card）或圆形（图标），带 `glow` 光晕动效
  - 步骤 1：黄绿色光晕（`Y2K.lime`）
  - 步骤 2：粉色光晕（`Y2K.pink`）
  - 步骤 3：蓝色光晕（`Y2K.blue`）
- **Tooltip 气泡：** 深色背景 `#0e0e12`，彩色边框，带方向箭头，显示在高亮元素上方或旁边
  - 内容：步骤编号（monospace）+ 步骤标题 + 子流程说明
- **「跳过」按钮：** 浮于遮罩左上角或右上角，半透明白色药丸样式

---

## 架构

### 新增文件

- `lib/services/onboarding_service.dart` — 状态管理（SharedPreferences 读写）
- `lib/widgets/onboarding_overlay.dart` — 聚光灯遮罩 Widget（CustomPainter + GlobalKey 定位）

### 修改文件

- `lib/main.dart`（`_HomePageState`）：
  - 为「新建测试」Card、档案图标、事件图标添加 `GlobalKey`
  - `initState` 检查是否需要展示引导
  - 用 `Stack` 将 `OnboardingOverlay` 叠加在 `Y2KScaffold` 之上
  - 拦截 3 个导航操作，在导航前调用 `OnboardingService.completeStep()` 并推进引导状态

### OnboardingService API

```dart
class OnboardingService {
  static Future<bool> shouldShow() async;       // 是否需要展示引导
  static Future<void> markDone() async;         // 标记引导已完成（跳过/退出/完成）
}
```

### OnboardingOverlay Widget

```dart
class OnboardingOverlay extends StatefulWidget {
  final int step;                    // 当前步骤 1-3
  final GlobalKey targetKey;         // 高亮目标
  final String stepLabel;            // 如 "STEP 1 / 3"
  final String title;
  final String subtitle;
  final Color accentColor;
  final bool isCircle;               // true=圆形镂空，false=圆角矩形
  final VoidCallback onSkip;
}
```

- 使用 `WidgetsBinding.instance.addPostFrameCallback` 获取 `targetKey` 的 `RenderBox` 位置和尺寸
- `CustomPainter` 绘制遮罩层 + 镂空 + 光晕
- Tooltip 位置根据目标框计算（优先显示在目标上方，空间不足时显示旁边）

---

## 数据流

```
App 启动
  └─ _HomePageState.initState()
       └─ OnboardingService.shouldShow()
            ├─ false → 正常渲染，无引导
            └─ true  → setState(_onboardingStep = 1)
                         → Stack 中插入 OnboardingOverlay(step=1)

用户点击高亮按钮
  └─ _HomePageState 拦截 onTap
       ├─ 若 _onboardingStep == 该按钮对应步骤
       │    └─ setState(_onboardingStep++)
       │         ├─ step <= 3 → 更新 overlay 到下一步
       │         └─ step > 3  → OnboardingService.markDone() → 移除 overlay
       └─ 正常导航逻辑继续执行

用户点击「跳过」
  └─ OnboardingService.markDone() → setState(_onboardingStep = 0) → 移除 overlay
```

---

## 不在范围内

- CreateSurveyPage / UserProfilePage / EventPage 内部不添加引导（方案甲：进入页面即完成）
- 无引导动画过渡（保持实现简单）
- 无引导重置功能（完成/跳过后永久不展示）
