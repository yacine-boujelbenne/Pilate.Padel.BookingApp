import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/motion/flex_motion.dart';

/// Original vector artwork: no network dependency or third-party asset license.
class StudioArt extends StatelessWidget {
  final bool compact;
  const StudioArt({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: FlexBreathing(
          child: SizedBox(
            width: compact ? 90 : 180,
            height: compact ? 90 : 180,
            child: CustomPaint(painter: _StudioArtPainter()),
          ),
        ),
      );
}

class _StudioArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 180, size.height / 180);
    final line = Paint()
      ..color = AppColors.lime
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawOval(const Rect.fromLTWH(8, 25, 160, 115), line);
    canvas.save();
    canvas.translate(90, 83);
    canvas.rotate(-math.pi / 4);
    canvas.drawOval(const Rect.fromLTWH(-70, -38, 140, 76), line);
    canvas.restore();
    canvas.drawCircle(
      const Offset(91, 84),
      43,
      Paint()..color = AppColors.lime,
    );
    final body = Paint()
      ..color = AppColors.forest
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(
      const Offset(102, 64),
      7,
      Paint()..color = AppColors.forest,
    );
    final pose = Path()
      ..moveTo(72, 63)
      ..lineTo(90, 80)
      ..lineTo(111, 88)
      ..lineTo(128, 76)
      ..moveTo(90, 80)
      ..lineTo(82, 101)
      ..lineTo(58, 106)
      ..moveTo(82, 101)
      ..lineTo(109, 108);
    canvas.drawPath(pose, body);
    canvas.drawCircle(
      const Offset(28, 39),
      9,
      Paint()..color = AppColors.peach,
    );
    canvas.drawCircle(
      const Offset(158, 114),
      6,
      Paint()..color = AppColors.lime,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
