import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../app/theme.dart';

class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    required this.initials,
    this.size = 44,
    this.imageUrl,
  });
  final String initials;
  final double size;
  final String? imageUrl;
  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.sagePale,
      ),
      child: Text(
        initials.isEmpty ? 'F' : initials.toUpperCase(),
        style: AppTextStyles.body.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.forest,
        ),
      ),
    );
    if (imageUrl == null || imageUrl!.trim().isEmpty) return fallback;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
        fadeInDuration: AppMotion.duration(context, AppMotion.standard),
      ),
    );
  }
}
