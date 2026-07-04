import 'package:flutter/material.dart';

/// The app's signature recurring motif: a soft, slightly irregular
/// underline stroke that reads as hand-drawn rather than a stock Material
/// indicator bar. Used in exactly two places by design: under the active
/// bottom-nav label, and under Home section headers — see the design
/// plan's restraint principle. Not meant to be sprinkled elsewhere.
class InkUnderline extends StatelessWidget {
  const InkUnderline({
    super.key,
    this.width = 28,
    this.color,
    this.strokeWidth = 2.5,
  });

  final double width;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: width,
      height: strokeWidth + 3,
      child: CustomPaint(
        painter: _InkUnderlinePainter(color: resolvedColor, strokeWidth: strokeWidth),
      ),
    );
  }
}

class _InkUnderlinePainter extends CustomPainter {
  _InkUnderlinePainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // A gentle single-wave path rather than a straight line — this is the
    // "hand-drawn" quality. Deliberately subtle: one shallow curve, not a
    // squiggle, so it reads as considered rather than decorative.
    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.05,
        size.width,
        size.height * 0.55,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _InkUnderlinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
