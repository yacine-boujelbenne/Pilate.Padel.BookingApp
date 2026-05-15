import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/locale_text.dart';
import 'avatar_widget.dart';

class CoachCard extends StatefulWidget {
  final String name;
  final String speciality;
  final VoidCallback? onEdit;
  final VoidCallback? onTap;

  const CoachCard({
    super.key,
    required this.name,
    required this.speciality,
    this.onEdit,
    this.onTap,
  });

  @override
  State<CoachCard> createState() => _CoachCardState();
}

class _CoachCardState extends State<CoachCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor:
          widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.mint : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.sageDark.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              AvatarWidget(
                  initials: widget.name.isNotEmpty ? widget.name[0] : 'C',
                  size: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w700)),
                    Text(widget.speciality, style: AppTextStyles.sessionMeta),
                  ],
                ),
              ),
              if (widget.onEdit != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: widget.onEdit,
                    style: TextButton.styleFrom(
                      foregroundColor:
                          _isHovered ? AppColors.sage : AppColors.sageDark,
                    ),
                    child: Text(
                      context.tr('Edit'),
                      style: AppTextStyles.buttonSecondary.copyWith(
                        color: _isHovered ? AppColors.sage : AppColors.sageDark,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
