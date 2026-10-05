import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/motion/flex_motion.dart';

class FlexPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  const FlexPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<FlexPrimaryButton> createState() => _FlexPrimaryButtonState();
}

class _FlexPrimaryButtonState extends State<FlexPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) {
          if (widget.onPressed != null && !widget.isLoading) {
            setState(() => _pressed = true);
          }
        },
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: FlexMotion.duration(context, FlexMotion.quick),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : widget.onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.forest.withAlpha(191),
                disabledForegroundColor: AppColors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              ),
              child: AnimatedSwitcher(
                duration: FlexMotion.duration(context, FlexMotion.quick),
                child: widget.isLoading
                    ? Semantics(
                        key: const ValueKey('processing'),
                        liveRegion: true,
                        label: 'Reserving your place',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.lime,
                                value:
                                    FlexMotion.reduced(context) ? 0.75 : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('Reserving your place…'),
                          ],
                        ),
                      )
                    : Text(
                        widget.label,
                        key: ValueKey(widget.label),
                        style: AppTextStyles.buttonPrimary,
                      ),
              ),
            ),
          ),
        ),
      );
}

class FlexSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const FlexSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.forest,
            minimumSize: const Size(48, 48),
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: Text(label, style: AppTextStyles.buttonSecondary),
        ),
      );
}
