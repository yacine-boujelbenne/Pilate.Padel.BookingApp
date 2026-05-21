import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/follow_controller.dart';
import 'modern_components.dart';
import 'modern_colors.dart';
import 'modern_theme.dart';

/// Follow/Unfollow button widget for coaches
/// Displays a heart icon that toggles between followed/unfollowed states
/// Features: Loading state with shimmer, animated state change, error handling
class FollowButton extends StatefulWidget {
  final String coachId;
  final VoidCallback? onFollowChanged;
  final double size;
  final bool showLabel;
  final Color? customColor;

  const FollowButton({
    super.key,
    required this.coachId,
    this.onFollowChanged,
    this.size = 48,
    this.showLabel = false,
    this.customColor,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onFollowToggle(FollowController controller) async {
    try {
      final wasFollowed = controller.isCoachFollowed(widget.coachId);

      await controller.toggleFollowStatus(widget.coachId);

      if (!wasFollowed) {
        _animationController.forward().then((_) {
          _animationController.reverse();
        });
      }

      widget.onFollowChanged?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FollowController>(
      builder: (context, followController, child) {
        final isFollowed = followController.isCoachFollowed(widget.coachId);
        final isLoading = followController.isLoading;

        if (isLoading) {
          return _buildShimmerButton();
        }

        return Tooltip(
          message: isFollowed ? 'Unfollow coach' : 'Follow coach',
          child: GestureDetector(
            onTap: () => _onFollowToggle(followController),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                gradient: isFollowed
                    ? ModernColors.accentGradient
                    : ModernColors.secondaryGradient,
                borderRadius: BorderRadius.circular(widget.size / 2),
                boxShadow: isFollowed
                    ? ModernShadows.mediumElevation
                    : ModernShadows.lightElevation,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Main heart icon
                  Icon(
                    isFollowed ? Icons.favorite : Icons.favorite_border,
                    color: isFollowed ? Colors.white : Colors.grey[600],
                    size: widget.size * 0.5,
                  ),

                  // Success animation (scaling + icon)
                  if (isFollowed)
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.pink.withOpacity(_opacityAnimation.value),
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                  // Success icon animation
                  if (isFollowed)
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Icon(
                        Icons.add,
                        color: Colors.pink.withOpacity(_opacityAnimation.value),
                        size: widget.size * 0.3,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerButton() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(widget.size / 2),
      ),
      child: Center(
        child: SizedBox(
          width: widget.size * 0.3,
          height: widget.size * 0.3,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      ),
    );
  }
}
