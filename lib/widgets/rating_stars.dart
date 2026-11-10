import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Five stars (full / half / empty), the rating number and the review
/// count: «★★★★☆ 3.9 · 120 отзывов».
class RatingStars extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final double size;

  const RatingStars({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.size = 14,
  });

  static const _starColor = Color(0xFFE0A84F);

  IconData _iconFor(int i) {
    if (rating >= i + 1) return Icons.star_rounded;
    if (rating >= i + 0.5) return Icons.star_half_rounded;
    return Icons.star_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 5; i++)
          Icon(_iconFor(i), size: size, color: _starColor),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '${rating.toStringAsFixed(1)} · ${Format.reviews(reviewCount)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: size - 2,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
