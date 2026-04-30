import 'dart:async';
import 'dart:math' show pi, sin, cos;

import 'package:flutter/material.dart';
import 'home_page.dart';
import '../theme/y2k_theme.dart';

/// Y2K × Fluid 融合风格 Splash 页面
class SplashPage extends StatefulWidget {
  final Widget nextPage;

  const SplashPage({super.key, this.nextPage = const HomePage()});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _masterController;
  late AnimationController _fluidController;

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

    _fluidController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    // 1. 整体淡入
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.0, 0.14, curve: Curves.easeOut),
      ),
    );

    // 2. 图标弹性缩放 + 旋转
    // 注意：TweenSequence 要求 t 在 [0,1] 之间，不能使用 easeOutBack
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.08, 0.25, curve: Curves.easeOutCubic),
      ),
    );

    _iconRotate = Tween<double>(begin: -0.12, end: 0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.08, 0.25, curve: Curves.easeOutCubic),
      ),
    );

    // 3. 标题上滑 + 淡入
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

    // 4. 副标题上滑 + 淡入
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

    // 5. 进度条展开
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

    // 6. 整体淡出
    _fadeOut = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _masterController,
        curve: const Interval(0.83, 1.0, curve: Curves.easeIn),
      ),
    );

    _masterController.forward();

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
          // 流体背景层
          _buildFluidBackground(),
          // 内容层
          _buildContent(),
        ],
      ),
    );
  }

  /// 使用 LayoutBuilder 安全获取尺寸，避免溢出
  Widget _buildFluidBackground() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        
        return AnimatedBuilder(
          animation: _fluidController,
          builder: (context, child) {
            final t = _fluidController.value;
            
            return Stack(
              children: [
                // 基础背景
                Container(color: Y2K.bg),
                
                // Blob 1: 粉色 (右上)
                _buildBlob(
                  color: Y2K.pink.withValues(alpha: 0.15),
                  size: 280,
                  cx: w * 0.70,
                  cy: h * 0.15,
                  orbit: 40,
                  phase: 0,
                  t: t,
                ),
                
                // Blob 2: 酸橙绿 (左下)
                _buildBlob(
                  color: Y2K.lime.withValues(alpha: 0.12),
                  size: 240,
                  cx: w * 0.25,
                  cy: h * 0.65,
                  orbit: 35,
                  phase: 2.1,
                  t: t,
                ),
                
                // Blob 3: 蓝色 (右下)
                _buildBlob(
                  color: Y2K.blue.withValues(alpha: 0.10),
                  size: 220,
                  cx: w * 0.75,
                  cy: h * 0.75,
                  orbit: 30,
                  phase: 4.2,
                  t: t,
                ),
                
                // Blob 4: 金色 (左上)
                _buildBlob(
                  color: Y2K.gold.withValues(alpha: 0.08),
                  size: 160,
                  cx: w * 0.20,
                  cy: h * 0.30,
                  orbit: 25,
                  phase: 1.5,
                  t: t,
                ),
                
                // 顶部高光
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.3, -0.3),
                      radius: 1.0,
                      colors: [
                        Colors.white.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 单个流体 Blob — 使用 Transform.translate 替代 Positioned，避免溢出
  Widget _buildBlob({
    required Color color,
    required double size,
    required double cx,
    required double cy,
    required double orbit,
    required double phase,
    required double t,
  }) {
    final angle = t * 2 * pi + phase;
    final dx = cos(angle) * orbit;
    final dy = sin(angle * 0.7) * orbit * 0.6;
    final breathe = 1.0 + sin(t * 2 * pi + phase) * 0.06;
    
    return Transform.translate(
      offset: Offset(cx - size / 2 + dx, cy - size / 2 + dy),
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
                color,
                color.withValues(alpha: 0.5),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }

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

            // 毛玻璃图标
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
                  color: Colors.white.withValues(alpha: 0.80),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Y2K.ink.withValues(alpha: 0.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Y2K.pink.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Y2K.lime.withValues(alpha: 0.08),
                      blurRadius: 32,
                      offset: const Offset(-8, -4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.favorite_border_rounded,
                  size: 36,
                  color: Y2K.ink.withValues(alpha: 0.75),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // 标题
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
                      color: Y2K.pink.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 副标题胶囊
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
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: Y2K.ink.withValues(alpha: 0.06),
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
                    color: Y2K.ink.withValues(alpha: 0.40),
                  ),
                ),
              ),
            ),

            const Spacer(flex: 2),

            // 进度条
            AnimatedBuilder(
              animation: _masterController,
              builder: (context, child) {
                return Opacity(
                  opacity: _progressFade.value,
                  child: Container(
                    width: 120,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Y2K.ink.withValues(alpha: 0.05),
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
                                Y2K.pink.withValues(alpha: 0.5),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
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
