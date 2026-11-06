import 'package:flutter/material.dart';
import 'package:rive/rive.dart' as rive;
import '../../app/theme.dart';

/// Success Check by guidorosso (CC BY 4.0), bundled with attribution.
class ConfirmationMotion extends StatefulWidget {
  const ConfirmationMotion({super.key});
  @override
  State<ConfirmationMotion> createState() => _ConfirmationMotionState();
}

class _ConfirmationMotionState extends State<ConfirmationMotion> {
  rive.File? _file;
  rive.Artboard? _artboard;
  _OncePainter? _painter;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && !MediaQuery.disableAnimationsOf(context)) {
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final file = await rive.File.asset(
        'assets/animations/success_check.riv',
        riveFactory: rive.Factory.flutter,
      );
      if (!mounted) {
        file?.dispose();
        return;
      }
      final artboard = file?.defaultArtboard();
      if (artboard == null || artboard.animationCount() == 0) {
        artboard?.dispose();
        file?.dispose();
        return;
      }
      final painter = _OncePainter();
      setState(() {
        _file = file;
        _artboard = artboard;
        _painter = painter;
      });
    } catch (_) {
      // A decorative asset must never prevent the reservation from being shown.
    }
  }

  @override
  void dispose() {
    _painter?.dispose();
    _artboard?.dispose();
    _file?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 112,
      width: 112,
      child: _artboard != null && !MediaQuery.disableAnimationsOf(context)
          ? rive.RiveArtboardWidget(artboard: _artboard!, painter: _painter!)
          : const Icon(
              Icons.check_circle_outline_rounded,
              size: 76,
              color: AppColors.greenDark,
            ),
    ),
  );
}

/// A success gesture plays once even if the source timeline is a loop.
final class _OncePainter extends rive.BasicArtboardPainter {
  _OncePainter() : super(fit: rive.Fit.contain);
  rive.Animation? _animation;
  double _elapsed = 0;
  @override
  void artboardChanged(rive.Artboard artboard) {
    super.artboardChanged(artboard);
    _animation?.dispose();
    _animation = artboard.animationAt(0);
    _elapsed = 0;
    notifyListeners();
  }

  @override
  bool advance(double elapsedSeconds) {
    final animation = _animation;
    if (animation == null || _elapsed >= animation.duration) return false;
    _elapsed = (_elapsed + elapsedSeconds).clamp(0, animation.duration);
    animation.time = _elapsed;
    animation.apply();
    return true;
  }

  @override
  void dispose() {
    _animation?.dispose();
    super.dispose();
  }
}
