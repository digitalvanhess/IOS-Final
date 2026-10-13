import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';

/// "Сегодня можно потратить" ring: arc shows the share of today's limit
/// that is still left, with the amount stacked in the center.
class BudgetRing extends StatelessWidget {
  final int leftToday;
  final int dailyLimit;
  final double size;

  const BudgetRing({
    super.key,
    required this.leftToday,
    required this.dailyLimit,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    final overspent = leftToday < 0;
    final progress = dailyLimit <= 0
        ? 0.0
        : (leftToday / dailyLimit).clamp(0.0, 1.0);
    final color = overspent ? AppColors.danger : AppColors.accent;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => CustomPaint(
              size: Size.square(size),
              painter: _RingPainter(progress: value, color: color),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(size * 0.14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  child: Text(
                    Format.money(leftToday),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                      color: overspent
                          ? AppColors.danger
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  overspent
                      ? 'перерасход за день'
                      : 'из ${Format.money(dailyLimit)} на день',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    final track = Paint()
      ..color = AppColors.cardLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
