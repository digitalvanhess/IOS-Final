import 'package:flutter/material.dart';

import '../models/expense.dart';

/// Expense photo with a category-colored fallback, so a slow or missing
/// connection never breaks the layout.
class ExpenseImage extends StatelessWidget {
  final Expense expense;
  final double iconSize;

  const ExpenseImage({super.key, required this.expense, this.iconSize = 22});

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: expense.category.color.withValues(alpha: 0.18),
      child: Center(
        child: Icon(
          expense.category.icon,
          size: iconSize,
          color: expense.category.color,
        ),
      ),
    );

    if (!expense.hasImage) return fallback;

    return Image.network(
      expense.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : fallback,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}
