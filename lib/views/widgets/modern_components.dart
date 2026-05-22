import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'modern_colors.dart';
import 'modern_theme.dart';

/// GlassCard - A container with glassmorphism effect
/// Features: Blur effect, gradient border, soft shadows
class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final double blurAmount;
  final bool showBorder;
  final LinearGradient? borderGradient;

  const GlassCard({super.key});

  const GlossCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.blurAmount = 10,
    this.showBorder = true,
    this.borderGradient,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(ModernRadius.lg),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: ModernColors.glassLight.withOpacity(0.5),
            border: showBorder
                ? Border.all(color: ModernColors.glassLighter, width: 1.5)
                : null,
            borderRadius: BorderRadius.circular(ModernRadius.lg),
            boxShadow: ModernShadows.mediumElevation,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      content = GestureDetector(onTap: onTap, child: content);
    }

    return Container(margin: margin, child: content);
  }
}

/// ModernButton - Button with gradient background and smooth animations
/// Features: Gradient fill, hover effect, ripple animation
class ModernButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final LinearGradient? gradient;
  final double? width;
  final double height;
  final TextStyle? textStyle;
  final IconData? icon;
  final bool isLoading;
  final bool isEnabled;

  const ModernButton({
    super.key,
    required this.label,
    this.onPressed,
    this.gradient,
    this.width,
    this.height = 56,
    this.textStyle,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: ModernCurves.easeInOutSmooth),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPressed() {
    if (!widget.isEnabled || widget.isLoading) return;
    _controller.forward().then((_) => _controller.reverse());
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ?? ModernColors.primaryGradient;
    final opacity = widget.isEnabled ? 1.0 : 0.5;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: _onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: ModernCurves.easeInOutSmooth,
            width: widget.width ?? double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(ModernRadius.lg),
              boxShadow: _isHovered
                  ? ModernShadows.highElevation
                  : ModernShadows.mediumElevation,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _onPressed,
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          height: ModernSpacing.md,
                          width: ModernSpacing.md,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(widget.icon, color: Colors.white),
                              const SizedBox(width: ModernSpacing.sm),
                            ],
                            Text(
                              widget.label,
                              style:
                                  widget.textStyle ??
                                  ModernTypography.labelLarge.copyWith(
                                    color: Colors.white,
                                  ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ModernTextField - Text input field with modern styling
/// Features: Clean design, focus animation, error state
class ModernTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? errorText;
  final TextInputType keyboardType;
  final int maxLines;
  final int minLines;
  final bool obscureText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final VoidCallback? onSuffixTap;

  const ModernTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines = 1,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.validator,
    this.onSuffixTap,
  });

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: ModernCurves.easeInOutSmooth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label.isNotEmpty) ...[
            Text(widget.label, style: ModernTypography.labelMedium),
            const SizedBox(height: ModernSpacing.sm),
          ],
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            minLines: widget.obscureText ? 1 : widget.minLines,
            onChanged: widget.onChanged,
            style: ModernTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: widget.hint,
              errorText: widget.errorText,
              filled: true,
              fillColor: hasError
                  ? ModernColors.errorLightest
                  : ModernColors.surfaceAlt,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: ModernSpacing.lg,
                vertical: ModernSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ModernRadius.md),
                borderSide: BorderSide(
                  color: hasError
                      ? ModernColors.error
                      : ModernColors.dividerLight,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ModernRadius.md),
                borderSide: BorderSide(
                  color: hasError
                      ? ModernColors.error
                      : ModernColors.dividerLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ModernRadius.md),
                borderSide: BorderSide(
                  color: hasError ? ModernColors.error : ModernColors.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(ModernRadius.md),
                borderSide: const BorderSide(color: ModernColors.error),
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused
                          ? ModernColors.primary
                          : ModernColors.textTertiary,
                    )
                  : null,
              suffixIcon: widget.suffixIcon != null
                  ? GestureDetector(
                      onTap: widget.onSuffixTap,
                      child: Icon(
                        widget.suffixIcon,
                        color: _isFocused
                            ? ModernColors.primary
                            : ModernColors.textTertiary,
                      ),
                    )
                  : null,
              hintStyle: ModernTypography.bodyMedium.copyWith(
                color: ModernColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// NotificationBadge - Badge showing notification count
/// Features: Glassmorphic design, pulse animation, customizable colors
class NotificationBadge extends StatefulWidget {
  final int count;
  final Color backgroundColor;
  final Color textColor;
  final double size;

  const NotificationBadge({
    super.key,
    this.count = 0,
    this.backgroundColor = ModernColors.error,
    this.textColor = Colors.white,
    this.size = 24,
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.count > 0) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(NotificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > 0 && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.count == 0) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) {
      return const SizedBox.shrink();
    }

    return ScaleTransition(
      scale: _pulseAnimation,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.size / 2),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.backgroundColor.withOpacity(0.9),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(widget.size / 2),
              boxShadow: ModernShadows.mediumElevation,
            ),
            child: Center(
              child: Text(
                widget.count > 99 ? '99+' : widget.count.toString(),
                style: ModernTypography.labelMedium.copyWith(
                  color: widget.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// AnimatedNotificationIcon - Icon that pulses when unread notifications exist
/// Features: Customizable icon, color animation, smooth pulsing effect
class AnimatedNotificationIcon extends StatefulWidget {
  final IconData icon;
  final bool hasNotifications;
  final Color activeColor;
  final Color inactiveColor;
  final double size;
  final VoidCallback? onTap;

  const AnimatedNotificationIcon({
    super.key,
    required this.icon,
    this.hasNotifications = false,
    this.activeColor = ModernColors.primary,
    this.inactiveColor = ModernColors.textTertiary,
    this.size = 24,
    this.onTap,
  });

  @override
  State<AnimatedNotificationIcon> createState() =>
      _AnimatedNotificationIconState();
}

class _AnimatedNotificationIconState extends State<AnimatedNotificationIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _colorAnimation =
        ColorTween(
          begin: widget.activeColor,
          end: widget.activeColor.withOpacity(0.5),
        ).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );

    if (widget.hasNotifications) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedNotificationIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasNotifications && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.hasNotifications) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            return Icon(
              widget.icon,
              size: widget.size,
              color: widget.hasNotifications
                  ? _colorAnimation.value ?? widget.activeColor
                  : widget.inactiveColor,
            );
          },
        ),
      ),
    );
  }
}

/// Helper function to build a glossy modal with glassmorphism
/// Usage: showDialog(context: context, builder: buildGlassModal(...))
Widget buildGlassModal({
  required BuildContext context,
  required String title,
  required Widget content,
  Widget? footer,
  VoidCallback? onClose,
}) {
  return Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(ModernSpacing.lg),
    child: Center(
      child: GlassCard(
        width: 400,
        padding: const EdgeInsets.all(ModernSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: ModernTypography.headlineSmall),
                GestureDetector(
                  onTap: onClose ?? () => Navigator.pop(context),
                  child: Icon(Icons.close, color: ModernColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: ModernSpacing.lg),
            content,
            if (footer != null) ...[
              const SizedBox(height: ModernSpacing.lg),
              footer,
            ],
          ],
        ),
      ),
    ),
  );
}

/// Helper function to create a shimmer loading effect
/// Usage: buildShimmerEffect(width: 200, height: 100)
Widget buildShimmerEffect({
  required double width,
  required double height,
  double borderRadius = ModernRadius.md,
}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          ModernColors.backgroundDark,
          ModernColors.background,
          ModernColors.backgroundDark,
        ],
      ),
    ),
  );
}

/// Helper function to build a modern box shadow
/// Usage: decoration: BoxDecoration(boxShadow: [buildSoftShadow()])
BoxShadow buildSoftShadow({
  double blurRadius = 8,
  Offset offset = const Offset(0, 4),
  double spreadRadius = 0,
  Color color = const Color(0x1A000000),
}) {
  return BoxShadow(
    color: color,
    offset: offset,
    blurRadius: blurRadius,
    spreadRadius: spreadRadius,
  );
}
