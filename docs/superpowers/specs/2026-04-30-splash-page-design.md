# Splash Page 设计文档

**日期**: 2026-04-30  
**作者**: AI Assistant  
**状态**: 已批准，等待实现计划

---

## 1. 需求背景

为 Flutter 应用 Pulse（人格匹配测试 App）增加启动时的 Splash 页面，展示品牌标识和加载状态，提升应用启动体验。

### 约束条件
- **每次启动都显示**（非仅首次）
- **简单 Logo + 应用名称 + 加载动画**
- **纯 Flutter Widget 实现**（不引入第三方依赖）
- **遵循现有 Y2K 设计系统**
- **使用 StatefulWidget 状态管理**（与项目现有模式一致）

---

## 2. 设计决策

### 2.1 方案选择

从 3 个候选方案中选择 **方案 A（纯 Flutter Widget 实现）**。

**原因**:
- 需求明确为简单展示，不需要原生启动画面或复杂多媒体
- 零额外依赖，与现有架构完全一致
- Y2K 主题可直接复用，无需额外适配工作
- 代码完全可控，后续扩展灵活

### 2.2 视觉设计

| 元素 | 值 | 说明 |
|------|-----|------|
| 背景色 | `#FFF5E1` (Y2K.bg) | 米色背景，与整个应用一致 |
| 应用图标 | `assets/icon_source.png` | 60×60 dp，居中展示 |
| 应用名称 | "Pulse" | 使用 `Y2K.displayMd`（34px, Bold, `#0E0E12`） |
| 加载指示器 | `CircularProgressIndicator` | 颜色为 `Y2K.pink` (`#FF5EA8`) |
| 无硬边阴影 | — | Splash 保持简洁，不使用卡片阴影 |

### 2.3 动画与时序

| 阶段 | 动画 | 时长 | 曲线 |
|------|------|------|------|
| 入场 | `AnimatedOpacity` 0 → 1 | 600ms | `Curves.easeOut` |
| 加载 | `CircularProgressIndicator` 持续旋转 | — | — |
| 离场 | `AnimatedOpacity` 1 → 0 | 500ms | `Curves.easeIn` |
| 总停留 | 入场后等待 | 2.5s | — |

**导航**: 使用 `Navigator.pushReplacement()` 跳转至 `HomePage`，防止用户返回到 Splash。

---

## 3. 架构与数据流

### 3.1 文件结构

```
lib/
├── pages/
│   └── splash_page.dart          # 新建：Splash 页面 Widget
├── main.dart                     # 修改：home 属性改为 SplashPage
```

### 3.2 组件职责

| 组件 | 职责 |
|------|------|
| `SplashPage` (StatefulWidget) | 控制入场动画、定时器、离场动画、页面跳转 |
| `build()` | 渲染居中的图标、文字、进度指示器 |
| `initState()` | 启动入场动画和延迟跳转计时器 |
| `dispose()` | 清理动画控制器和计时器，防止内存泄漏 |

### 3.3 数据流

```
main.dart → SplashPage → 延迟 2.5s → Navigator.pushReplacement → HomePage
                     ↓
              AnimatedOpacity (入场/离场)
              CircularProgressIndicator (加载)
```

---

## 4. 详细设计

### 4.1 SplashPage Widget

```dart
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();

    _timer = Timer(const Duration(milliseconds: 2500), () {
      _controller.reverse().then((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Y2K.bg,
      body: FadeTransition(
        opacity: _opacity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('icon_source.png', width: 60, height: 60),
              const SizedBox(height: 24),
              const Text('Pulse', style: Y2K.displayMd),
              const SizedBox(height: 48),
              CircularProgressIndicator(
                color: Y2K.pink,
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 4.2 pubspec.yaml 修改

需要在 `flutter:` 节下添加 `assets:` 声明，使 `icon_source.png` 可在运行时加载：

```yaml
flutter:
  uses-material-design: true
  assets:
    - icon_source.png
```

> 注：`icon_source.png` 已存在于项目根目录，直接声明即可。若希望统一放到 `assets/` 目录下，需先移动文件再更新声明路径。

### 4.3 main.dart 修改

将 `home: const HomePage()` 改为 `home: const SplashPage()`。

`HomePage` 的导入保留（Splash 内部导航到它）。

---

## 5. 错误处理

- **导航前检查 `mounted`**: 防止 Widget 已销毁时调用 `Navigator`
- **dispose 清理**: 必须取消 `Timer` 和 `AnimationController`，避免内存泄漏
- **异常安全**: `Navigator.pushReplacement` 在 `then` 回调中执行，确保动画完成后再跳转

---

## 6. 测试策略

- **Widget Test**: 验证 SplashPage 是否正确渲染图标、文字、进度指示器
- **导航 Test**: 验证 2.5s 后是否正确导航到 HomePage
- **内存 Test**: 验证 Widget 销毁时 Timer 和 AnimationController 被正确清理

---

## 7. 未解决问题

无。

---

## 8. 变更记录

| 日期 | 作者 | 变更 |
|------|------|------|
| 2026-04-30 | AI Assistant | 初稿创建 |
