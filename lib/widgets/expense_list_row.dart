import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'category_tag.dart';
import 'favorite_button.dart';

/// Flat row for the list mode of "Все траты": category avatar, title,
/// category tag with the day, amount and a favorite star.
class ExpenseListRow extends StatelessWidget {
  final Expense expense;
  final bool isFavorite;
  final ValueChanged<bool> onFavoriteChanged;
  final VoidCallback onTap;

  const ExpenseListRow({
    super.key,
    required this.expense,
    required this.isFavorite,
    required this.onFavoriteChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = expense.category;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: category.color.withValues(alpha: 0.18),
              child: Icon(category.icon, size: 20, color: category.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(child: CategoryTag(category: category)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          Format.relativeDay(expense.date),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              Format.money(-expense.amount),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            FavoriteButton(
              isFavorite: isFavorite,
              onChanged: onFavoriteChanged,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
