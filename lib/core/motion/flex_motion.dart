import 'package:flutter/material.dart';

/// Shared motion tokens. All decorative motion respects the OS preference.
class FlexMotion {
  static const quick = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 260);
  static const entrance = Duration(milliseconds: 420);
  static const celebration = Duration(milliseconds: 800);
  static const curve = Curves.easeOutCubic;

  static bool reduced(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;

  static Duration duration(BuildContext context, Duration value) =>
      reduced(context) ? Duration.zero : value;
}

class FlexEntrance extends StatelessWidget {
  final Widget child;
  const FlexEntrance({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (FlexMotion.reduced(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: FlexMotion.entrance,
      curve: FlexMotion.curve,
      child: child,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

/// A small reusable breathing loop, stopped when reduced motion is requested.
class FlexBreathing extends StatefulWidget {
  final Widget child;
  const FlexBreathing({super.key, required this.child});

  @override
  State<FlexBreathing> createState() => _FlexBreathingState();
}

class _FlexBreathingState extends State<FlexBreathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
    lowerBound: 0.97,
    upperBound: 1.03,
    value: 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (FlexMotion.reduced(context)) {
      _controller.stop();
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _controller, child: widget.child);
}
