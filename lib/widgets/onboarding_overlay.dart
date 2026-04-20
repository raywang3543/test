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
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
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
                  color: widget.accentColor.withValues(alpha: 0.35),
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
        ..color = accentColor.withValues(alpha: 0.45)
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
