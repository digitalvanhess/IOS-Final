import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Network photo of a store product (LW10).
///
/// Store photos are shot on white, so they sit on a white rounded tile
/// that reads well on the dark theme. Shows a small spinner while loading
/// and an icon when the image fails (for example in airplane mode).
class ProductImage extends StatelessWidget {
  final String url;
  final double radius;
  final EdgeInsets padding;
  final double scale;
  final Alignment alignment;

  const ProductImage({
    super.key,
    required this.url,
    this.radius = 14,
    this.padding = const EdgeInsets.all(6),
    this.scale = 1,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(
        color: Colors.white,
        child: Padding(
          padding: padding,
          child: Transform.scale(
            scale: scale,
            alignment: alignment,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accentDark,
                    ),
                  ),
                );
              },
              errorBuilder: (_, _, _) => const Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
