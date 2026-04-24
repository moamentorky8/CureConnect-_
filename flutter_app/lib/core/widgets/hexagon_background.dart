import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class HexagonBackground extends StatelessWidget {
  const HexagonBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(decoration: const BoxDecoration(gradient: AppColors.shellGradient)),
        const Positioned.fill(child: _GlowFields()),
        const Positioned.fill(child: _HexFrame()),
        child,
      ],
    );
  }
}

class _GlowFields extends StatelessWidget {
  const _GlowFields();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        Positioned(top: -120, left: -40, child: _GlowOrb(color: AppColors.logoCyan)),
        Positioned(top: 180, right: -80, child: _GlowOrb(color: AppColors.logoMint)),
        Positioned(bottom: -100, left: 80, child: _GlowOrb(color: AppColors.medicalBlue)),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(0.35), Colors.transparent],
        ),
      ),
    );
  }
}

class _HexFrame extends StatelessWidget {
  const _HexFrame();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _HexPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.34;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = const LinearGradient(
        colors: [AppColors.logoCyan, AppColors.logoMint],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.4));

    Path polygon(double scale) {
      final path = Path();
      for (var i = 0; i < 6; i++) {
        final angle = (60 * i - 30) * 3.1415926535 / 180;
        final point = Offset(
          center.dx + radius * scale * math.cos(angle),
          center.dy + radius * scale * math.sin(angle),
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      return path;
    }

    canvas.drawPath(polygon(1.0), paint..color = AppColors.logoCyan);
    canvas.drawPath(polygon(1.18), paint..color = AppColors.logoMint.withOpacity(0.3));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

