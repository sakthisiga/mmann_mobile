import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Vector-rendered Indian National Flag (Tiranga) widget replacing flag emojis.
class IndiaFlagIcon extends StatelessWidget {
  final double width;
  final double height;

  const IndiaFlagIcon({
    super.key,
    this.width = 21,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2.5),
      child: CustomPaint(
        size: Size(width, height),
        painter: _IndiaFlagPainter(),
      ),
    );
  }
}

class _IndiaFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stripeHeight = size.height / 3;

    // Top Saffron stripe (#FF9933)
    final saffronPaint = Paint()..color = const Color(0xFFFF9933);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, stripeHeight),
      saffronPaint,
    );

    // Middle White stripe (#FFFFFF)
    final whitePaint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRect(
      Rect.fromLTWH(0, stripeHeight, size.width, stripeHeight),
      whitePaint,
    );

    // Bottom India Green stripe (#138808)
    final greenPaint = Paint()..color = const Color(0xFF138808);
    canvas.drawRect(
      Rect.fromLTWH(0, stripeHeight * 2, size.width, stripeHeight),
      greenPaint,
    );

    // Ashoka Chakra in Navy Blue (#000080)
    final center = Offset(size.width / 2, size.height / 2);
    final radius = stripeHeight * 0.38;

    final chakraRingPaint = Paint()
      ..color = const Color(0xFF000080)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, radius, chakraRingPaint);

    final chakraHubPaint = Paint()
      ..color = const Color(0xFF000080)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.25, chakraHubPaint);

    // 8 primary vector spokes for clarity at small icon sizes
    final spokePaint = Paint()
      ..color = const Color(0xFF000080)
      ..strokeWidth = 0.45;
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi) / 4;
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, end, spokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

