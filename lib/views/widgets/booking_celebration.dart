import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/motion/flex_motion.dart';

class BookingCelebration extends StatelessWidget {
  const BookingCelebration({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Reservation confirmed',
        image: true,
        child: ExcludeSemantics(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: FlexMotion.reduced(context) ? 1 : 0, end: 1),
            duration: FlexMotion.duration(context, FlexMotion.celebration),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => SizedBox(
              width: 160,
              height: 160,
              child: CustomPaint(painter: _CelebrationPainter(value)),
            ),
          ),
        ),
      );
}

class _CelebrationPainter extends CustomPainter {
  final double progress;
  _CelebrationPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.drawCircle(
      center,
      51 * (0.8 + 0.2 * progress),
      Paint()..color = AppColors.lime,
    );
    final check = Path()
      ..moveTo(center.dx - 19, center.dy)
      ..lineTo(center.dx - 4, center.dy + 15)
      ..lineTo(center.dx + 23, center.dy - 16);
    final metric = check.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = AppColors.forest
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final radius = 56 + 18 * progress;
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * radius,
        3 * progress,
        Paint()..color = i.isEven ? AppColors.peach : AppColors.sage,
      );
    }
  }

  @override
  bool shouldRepaint(_CelebrationPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
