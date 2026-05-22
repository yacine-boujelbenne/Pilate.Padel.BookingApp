import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/follow_controller.dart';
import 'modern_theme.dart';

/// Widget displaying the number of followers for a coach
/// Features: Heart icon with follower count, glassmorphism design, real-time updates
class FollowersBadge extends StatefulWidget {
  final String coachId;
  final bool showLabel;
  final VoidCallback? onTap;
  final double fontSize;

  const FollowersBadge({
    super.key,
    required this.coachId,
    this.showLabel = true,
    this.onTap,
    this.fontSize = 14,
  });

  @override
  State<FollowersBadge> createState() => _FollowersBadgeState();
}

class _FollowersBadgeState extends State<FollowersBadge> {
  @override
  void initState() {
    super.initState();
    _loadFollowerCount();
  }

  void _loadFollowerCount() async {
    try {
      final followController = context.read<FollowController>();
      await followController.getFollowerCount(widget.coachId);
    } catch (e) {
      // Silent error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FollowController>(
      builder: (context, followController, child) {
        final count = followController.getFollowerCountCached(widget.coachId);

        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ModernSpacing.md,
              vertical: ModernSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.pink.withOpacity(0.1),
                  Colors.red.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(ModernRadius.full),
              border: Border.all(
                color: Colors.pink.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite,
                  color: Colors.pink.shade600,
                  size: widget.fontSize + 2,
                ),
                const SizedBox(width: ModernSpacing.xs),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    color: Colors.pink.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: widget.fontSize,
                    fontFamily: 'Roboto',
                  ),
                  child: Text(
                    count > 999
                        ? '${(count / 1000).toStringAsFixed(1)}k'
                        : '$count',
                  ),
                ),
                if (widget.showLabel) ...[
                  const SizedBox(width: ModernSpacing.xs),
                  Text(
                    count == 1 ? 'follower' : 'followers',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: widget.fontSize - 2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
