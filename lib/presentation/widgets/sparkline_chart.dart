import 'dart:math';
import 'package:flutter/material.dart';

class SparklineChart extends StatelessWidget {
  final List<double> data;
  final bool isPositive;
  final double width;
  final double height;
  final bool showFill;

  const SparklineChart({
    super.key,
    required this.data,
    required this.isPositive,
    this.width = 64,
    this.height = 28,
    this.showFill = true,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(width: width, height: height);
    }

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          data: data,
          lineColor: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          fillGradient: showFill
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.25),
                    (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.0),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final Gradient? fillGradient;

  _SparklinePainter({
    required this.data,
    required this.lineColor,
    this.fillGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final minVal = data.reduce(min);
    final maxVal = data.reduce(max);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final points = <Offset>[];
    final dx = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final normalized = (data[i] - minVal) / range;
      final y = size.height - (normalized * (size.height - 4)) - 2;
      points.add(Offset(i * dx, y));
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // Draw Fill
    if (fillGradient != null) {
      final fillPath = Path.from(path);
      fillPath.lineTo(size.width, size.height);
      fillPath.lineTo(0, size.height);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = fillGradient!.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw Line
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.lineColor != lineColor;
  }
}
