import 'dart:async';

import 'package:flutter/material.dart';
import 'home_page.dart';
import '../theme/y2k_theme.dart';

/// 分镜式 Splash 页面
/// 
/// 动画时间线（总时长 3.6s）：
/// T+0ms     → 整体淡入开始
/// T+200ms   → 图标弹性缩放入场 (0→1.2→1)
/// T+600ms   → "Pulse" 标题上滑 + 淡入
/// T+1000ms  → 副标题上滑 + 淡入
/// T+1400ms  → 底部进度条从左到右展开
/// T+2400ms  → 加载完成，准备离场
/// T+3100ms  → 整体淡出 → 导航到首页
class SplashPage extends StatefulWidget {
  final Widget nextPage;

  const SplashPage({super.key, this.nextPage = const HomePage()});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _masterController;

  // 各元素独立的动画
  late Animation<double> _fadeIn;
  late Animation<double> _iconScale;
  late Animation<double> _iconRotate;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _subtitleFade;
  late Animation<double> _progressWidth;
  late Animation<double> _progressFade;
  late Animation<double> _fadeOut;

  Timer? _navigateTimer;

  @override
  void initState() {
    super.initState();

    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    // 1. 整体淡入 (0-400ms)
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.11, curve: Curves.easeOut),
      ),
    );

    // 2. 图标弹性缩放 (200-700ms)
    _iconScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 40),
    ]).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.055, 0.195, curve: Curves.easeOutBack),
      ),
    );

    // 图标轻微旋转
    _iconRotate = Tween<double>(begin: -0.15, end: 0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.055, 0.195, curve: Curves.easeOutBack),
      ),
    );

    // 3. 标题上滑 + 淡入 (600-1100ms)
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.165, 0.305, curve: Curves.easeOutCubic),
      ),
    );

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.165, 0.305, curve: Curves.easeOut),
      ),
    );

    // 4. 副标题上滑 + 淡入 (1000-1500ms)
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.275, 0.415, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.275, 0.415, curve: Curves.easeOut),
      ),
    );

    // 5. 进度条展开 (1400-2400ms)
    _progressWidth = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.385, 0.665, curve: Curves.easeInOutCubic),
      ),
    );

    _progressFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.385, 0.445, curve: Curves.easeOut),
      ),
    );

    // 6. 整体淡出 (3100-3600ms)
    _fadeOut = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.86, 1.0, curve: Curves.easeIn),
      ),
    );

    // 启动主动画
    _masterController.forward();

    // 2.4s 后准备导航（给 200ms 缓冲）
    _navigateTimer = Timer(const Duration(milliseconds: 3400), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => widget.nextPage,
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: a, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _masterController.dispose();
    _navigateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Y2K.bg,
      body: AnimatedBuilder(
        animation: _masterController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeOut.value < 1 ? _fadeIn : _fadeOut,
            child: child,
          );
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // ── 01 图标 ───────────────────────────────────────
              AnimatedBuilder(
                animation: _masterController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _iconScale.value,
                    child: Transform.rotate(
                      angle: _iconRotate.value,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Y2K.lime,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Y2K.ink,
                      width: Y2K.borderWidth,
                    ),
                    boxShadow: Y2K.shadow(offset: 4),
                  ),
                  child: const Icon(
                    Icons.favorite_border_rounded,
                    size: 36,
                    color: Y2K.ink,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ── 02 主标题 Pulse ───────────────────────────────
              AnimatedBuilder(
                animation: _masterController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _titleFade.value,
                    child: FractionalTranslation(
                      translation: _titleSlide.value,
                      child: child,
                    ),
                  );
                },
                child: const Text(
                  'Pulse',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                    height: 1.0,
                    color: Y2K.ink,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── 03 副标题 ─────────────────────────────────────
              AnimatedBuilder(
                animation: _masterController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _subtitleFade.value,
                    child: FractionalTranslation(
                      translation: _subtitleSlide.value,
                      child: child,
                    ),
                  );
                },
                child: Text(
                  '性格 · 匹配 · 测试',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: Y2K.ink.withValues(alpha: 0.5),
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // ── 04 进度条 ─────────────────────────────────────
              AnimatedBuilder(
                animation: _masterController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _progressFade.value,
                    child: Container(
                      width: 120,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Y2K.ink.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _progressWidth.value,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: Y2K.pink,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
