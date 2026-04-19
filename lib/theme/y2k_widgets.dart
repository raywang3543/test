import 'package:flutter/material.dart';
import 'y2k_theme.dart';

/// Chunky Y2K card with 2px black border and hard-edge shadow.
class Y2KCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color background;
  final Color borderColor;
  final double radius;
  final double shadowOffset;
  final Color shadowColor;
  final VoidCallback? onTap;

  const Y2KCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.background = Y2K.card,
    this.borderColor = Y2K.ink,
    this.radius = Y2K.radius,
    this.shadowOffset = 4,
    this.shadowColor = Y2K.ink,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radiusObj = BorderRadius.circular(radius);
    final container = Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: radiusObj,
        border: Border.all(color: borderColor, width: Y2K.borderWidth),
        boxShadow: shadowOffset > 0
            ? Y2K.shadow(offset: shadowOffset, color: shadowColor)
            : null,
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return container;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radiusObj,
        onTap: onTap,
        child: container,
      ),
    );
  }
}

/// Y2K pill button.
enum Y2KButtonKind { primary, dark, ghost, accent }

class Y2KButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Y2KButtonKind kind;
  final bool block;
  final Color? customBg;
  final Color? customFg;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  const Y2KButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.kind = Y2KButtonKind.dark,
    this.block = false,
    this.customBg,
    this.customFg,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (kind) {
      case Y2KButtonKind.primary:
        bg = Y2K.lime;
        fg = Y2K.ink;
        break;
      case Y2KButtonKind.dark:
        bg = Y2K.ink;
        fg = Y2K.bg;
        break;
      case Y2KButtonKind.ghost:
        bg = Colors.transparent;
        fg = Y2K.ink;
        break;
      case Y2KButtonKind.accent:
        bg = Y2K.pink;
        fg = Colors.white;
        break;
    }
    if (customBg != null) bg = customBg!;
    if (customFg != null) fg = customFg!;
    final disabled = onPressed == null;
    final radius = BorderRadius.circular(999);
    final button = AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: disabled ? 0.45 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: Border.all(color: Y2K.ink, width: Y2K.borderWidth),
          boxShadow: kind == Y2KButtonKind.ghost
              ? null
              : Y2K.shadow(offset: disabled ? 0 : 4),
        ),
        padding: padding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: fontSize + 3, color: fg),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onPressed,
        child: button,
      ),
    );
  }
}

/// Small pill chip (mono uppercase labels).
class Y2KChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const Y2KChip({
    super.key,
    required this.label,
    this.background = Y2K.chip,
    this.foreground = Y2K.ink,
    this.icon,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    final widget = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: Border.all(color: Y2K.ink, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: foreground,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return widget;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: radius, onTap: onTap, child: widget),
    );
  }
}

/// Small rectangular tag (like the accent tags in the design).
class Y2KTag extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const Y2KTag({
    super.key,
    required this.label,
    this.background = Y2K.lime,
    this.foreground = Y2K.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Y2K.ink, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: foreground,
        ),
      ),
    );
  }
}

/// Dotted background painter (Y2K motif).
class DotsBackground extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double spacing;

  const DotsBackground({
    super.key,
    required this.child,
    this.opacity = 0.18,
    this.spacing = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _DotsPainter(opacity: opacity, spacing: spacing),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _DotsPainter extends CustomPainter {
  final double opacity;
  final double spacing;
  _DotsPainter({required this.opacity, required this.spacing});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Y2K.ink.withValues(alpha: opacity);
    for (double y = spacing / 2; y < size.height; y += spacing) {
      for (double x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.spacing != spacing;
}

/// Segmented progress bar (like the design's chunky segbar).
class Y2KSegBar extends StatelessWidget {
  final int total;
  final int current; // current index (in progress)
  final double height;

  const Y2KSegBar({
    super.key,
    required this.total,
    required this.current,
    this.height = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        Color c;
        if (i < current) {
          c = Y2K.lime;
        } else if (i == current) {
          c = Y2K.pink;
        } else {
          c = Y2K.card;
        }
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == total - 1 ? 0 : 3),
            height: height,
            decoration: BoxDecoration(
              color: c,
              border: Border.all(color: Y2K.ink, width: 1.5),
            ),
          ),
        );
      }),
    );
  }
}

/// Dashed border divider.
class Y2KDashedDivider extends StatelessWidget {
  final Color color;
  final double height;
  const Y2KDashedDivider({super.key, this.color = Y2K.ink, this.height = 1});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _DashedPainter(color: color),
        size: Size.infinite,
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  final Color color;
  _DashedPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    const dash = 4.0, gap = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPainter oldDelegate) => false;
}

/// Marquee (scrolling) strip — decorative.
class Y2KMarquee extends StatefulWidget {
  final String text;
  final Color background;
  final Color foreground;
  final Duration duration;
  const Y2KMarquee({
    super.key,
    required this.text,
    this.background = Y2K.ink,
    this.foreground = Y2K.bg,
    this.duration = const Duration(seconds: 18),
  });

  @override
  State<Y2KMarquee> createState() => _Y2KMarqueeState();
}

class _Y2KMarqueeState extends State<Y2KMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      letterSpacing: 1.8,
      fontWeight: FontWeight.w700,
      color: widget.foreground,
    );
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: widget.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Y2K.ink, width: Y2K.borderWidth),
      ),
      clipBehavior: Clip.hardEdge,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _MarqueePainter(
            text: '  ${widget.text}  •  ',
            style: style,
            progress: _c.value,
          ),
        ),
      ),
    );
  }
}

class _MarqueePainter extends CustomPainter {
  final String text;
  final TextStyle style;
  final double progress;

  _MarqueePainter({
    required this.text,
    required this.style,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    if (tp.width <= 0) return;
    final double offset = (progress * tp.width) % tp.width;
    double x = -offset;
    while (x < size.width) {
      tp.paint(canvas, Offset(x, (size.height - tp.height) / 2));
      x += tp.width;
    }
  }

  @override
  bool shouldRepaint(covariant _MarqueePainter old) =>
      old.progress != progress || old.text != text;
}

/// Star/sparkle glyph (pure shape).
class Sparkle extends StatelessWidget {
  final double size;
  final Color color;
  const Sparkle({super.key, this.size = 14, this.color = Y2K.ink});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SparklePainter(color: color)),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;
  _SparklePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    final w = size.width, h = size.height;
    // 10-point star polygon matching design's clip-path
    final pts = [
      Offset(w * 0.50, 0),
      Offset(w * 0.61, h * 0.35),
      Offset(w * 0.98, h * 0.35),
      Offset(w * 0.68, h * 0.57),
      Offset(w * 0.79, h * 0.91),
      Offset(w * 0.50, h * 0.70),
      Offset(w * 0.21, h * 0.91),
      Offset(w * 0.32, h * 0.57),
      Offset(w * 0.02, h * 0.35),
      Offset(w * 0.39, h * 0.35),
    ];
    path.moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) => oldDelegate.color != color;
}

/// Rotated inline highlight label (like the "人类？" block in onboarding).
class Y2KHighlight extends StatelessWidget {
  final String text;
  final double angle; // radians
  final double fontSize;
  final Color background;
  final Color foreground;
  const Y2KHighlight({
    super.key,
    required this.text,
    this.angle = -0.035, // ~-2deg
    this.fontSize = 48,
    this.background = Y2K.ink,
    this.foreground = Y2K.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: fontSize * 0.22, vertical: 2),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: foreground,
            height: 1,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }
}

/// Standard Y2K page scaffold with cream background + back chip.
class Y2KScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool dots;
  final Color background;

  const Y2KScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.dots = false,
    this.background = Y2K.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: dots ? DotsBackground(child: body) : body,
    );
  }
}

/// Simple Y2K app bar that matches cream bg with chip back button.
class Y2KAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? stepLabel;
  final String title;
  final List<Widget> actions;
  final bool showBack;
  final VoidCallback? onBack;
  final Color background;

  const Y2KAppBar({
    super.key,
    required this.title,
    this.stepLabel,
    this.actions = const [],
    this.showBack = true,
    this.onBack,
    this.background = Y2K.bg,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (showBack)
              Y2KChip(
                label: '← 返回',
                background: Colors.transparent,
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
              ),
            if (showBack) const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (stepLabel != null)
                    Text(stepLabel!, style: Y2K.monoSm.copyWith(color: Y2K.muted)),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: Y2K.ink,
                    ),
                  ),
                ],
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}
