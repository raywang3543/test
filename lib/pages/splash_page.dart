import 'dart:async';
import 'dart:math' show pi, sin, cos;

import 'package:flutter/material.dart';
import 'home_page.dart';
import '../theme/y2k_theme.dart';

/// Y2K × Fluid 融合风格 Splash 页面
/// 
/// 配色：Y2K (米色背景 + 粉/绿/蓝强调色)
/// 动画：Fluid (浮动流体渐变形状 + 毛玻璃效果)
/// 结构：Storyboard 分镜式入场
///
/// 动画时间线：
/// T+0ms     → 背景淡入，流体形状开始浮动
/// T+300ms   → 毛玻璃图标弹性缩放入场
/// T+700ms   → "Pulse" 标题上滑 + 淡入
/// T+1100ms  → 副标题上滑 + 淡入
/// T+1500ms  → 底部进度条展开
/// T+3000ms  → 准备离场
/// T+3600ms  → 淡出 → 导航到首页
class SplashPage extends StatefulWidget {
  final Widget nextPage;

  const SplashPage({super.key, this.nextPage = const HomePage()});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  // 主动画控制器 (3.6s)
  late AnimationController _masterController;
  
  // 流体背景持续动画控制器 (无限循环)
  late AnimationController _fluidController;

  // 分镜入场动画
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

    // 流体背景持续浮动 (12秒一圈，无限循环)
    _fluidController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // 主分镜动画控制器
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    // 1. 整体淡入 (0-500ms)
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.14, curve: Curves.easeOut),
      ),
    );

    // 2. 图标弹性缩放 + 旋转 (300-900ms)
    _iconScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 45),
    ]).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.08, 0.25, curve: Curves.easeOutBack),
      ),
    );

    _iconRotate = Tween<double>(begin: -0.12, end: 0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.08, 0.25, curve: Curves.easeOutBack),
      ),
    );

    // 3. 标题上滑 + 淡入 (700-1200ms)
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.19, 0.33, curve: Curves.easeOutCubic),
      ),
    );

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.19, 0.33, curve: Curves.easeOut),
      ),
    );

    // 4. 副标题上滑 + 淡入 (1100-1600ms)
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.30, 0.44, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.30, 0.44, curve: Curves.easeOut),
      ),
    );

    // 5. 进度条展开 (1500-2600ms)
    _progressWidth = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.41, 0.72, curve: Curves.easeInOutCubic),
      ),
    );

    _progressFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.41, 0.50, curve: Curves.easeOut),
      ),
    );

    // 6. 整体淡出 (3000-3600ms)
    _fadeOut = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.83, 1.0, curve: Curves.easeIn),
      ),
    );

    _masterController.forward();

    // 3.4s 后导航
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
    _fluidController.dispose();
    _navigateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Y2K.bg,
      body: Stack(
        children: [
          // ===== 流体背景层 =====
          _buildFluidBackground(),
          
          // ===== 内容层 =====
          _buildContent(),
        ],
      ),
    );
  }

  /// 流体渐变背景
  Widget _buildFluidBackground() {
    return AnimatedBuilder(
      animation: _fluidController,
      builder: (context, child) {
        final t = _fluidController.value;
        
        return Stack(
          children: [
            // 基础背景
            Container(color: Y2K.bg),
            
            // Blob 1: 粉色 (右上)
            _buildFluidBlob(
              color: Y2K.pink.withValues(alpha: 0.18),
              size: 320,
              centerX: 0.75,
              centerY: 0.15,
              orbitRadius: 60,
              phase: 0,
              t: t,
            ),
            
            // Blob 2: 酸橙绿 (左下)
            _buildFluidBlob(
              color: Y2K.lime.withValues(alpha: 0.15),
              size: 280,
              centerX: 0.20,
              centerY: 0.70,
              orbitRadius: 50,
              phase: 2.1,
              t: t,
            ),
            
            // Blob 3: 蓝色 (右下)
            _buildFluidBlob(
              color: Y2K.blue.withValues(alpha: 0.12),
              size: 250,
              centerX: 0.80,
              centerY: 0.80,
              orbitRadius: 45,
              phase: 4.2,
              t: t,
            ),
            
            // Blob 4: 金色 (左上，小)
            _buildFluidBlob(
              color: Y2K.gold.withValues(alpha: 0.10),
              size: 180,
              centerX: 0.15,
              centerY: 0.25,
              orbitRadius: 35,
              phase: 1.5,
              t: t,
            ),
            
            // 微弱噪点纹理层 (可选，增加质感)
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.3, -0.3),
                  radius: 1.2,
                  colors: [
                    Colors.white.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 单个流体 Blob
  Widget _buildFluidBlob({
    required Color color,
    required double size,
    required double centerX,
    required double centerY,
    required double orbitRadius,
    required double phase,
    required double t,
  }) {
    // 使用正弦波创建浮动轨迹
    final angle = t * 2 * pi + phase;
    final offsetX = cos(angle) * orbitRadius;
    final offsetY = sin(angle * 0.7) * orbitRadius * 0.6;
    
    // 呼吸缩放效果
    final breathe = 1.0 + sin(t * 2 * pi + phase) * 0.08;
    
    return Positioned(
      left: centerX * MediaQuery.of(context).size.width - size / 2 + offsetX,
      top: centerY * MediaQuery.of(context).size.height - size / 2 + offsetY,
      child: Transform.scale(
        scale: breathe,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.2, -0.2),
              radius: 0.8,
              colors: [
                color.withValues(alpha: color.a * 1.5),
                color,
                color.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  /// 主内容
  Widget _buildContent() {
    return AnimatedBuilder(
      animation: _masterController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeOut.value < 1 ? _fadeIn : _fadeOut,
          child: child,
        );
      },
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),

            // ── 01 毛玻璃图标 ──────────────────────────────────
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
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Y2K.ink.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Y2K.pink.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Y2K.lime.withValues(alpha: 0.1),
                      blurRadius: 40,
                      offset: const Offset(-10, -5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.favorite_border_rounded,
                  size: 36,
                  color: Y2K.ink.withValues(alpha: 0.8),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ── 02 主标题 Pulse ────────────────────────────────
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
              child: Text(
                'Pulse',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2.5,
                  height: 1.0,
                  color: Y2K.ink,
                  shadows: [
                    Shadow(
                      color: Y2K.pink.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── 03 副标题 ──────────────────────────────────────
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: Y2K.ink.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Text(
                  '性格 · 匹配 · 测试',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                    color: Y2K.ink.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),

            const Spacer(flex: 2),

            // ── 04 进度条 ──────────────────────────────────────
            AnimatedBuilder(
              animation: _masterController,
              builder: (context, child) {
                return Opacity(
                  opacity: _progressFade.value,
                  child: Container(
                    width: 120,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Y2K.ink.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _progressWidth.value,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Y2K.pink,
                                Y2K.pink.withValues(alpha: 0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: Y2K.pink.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
