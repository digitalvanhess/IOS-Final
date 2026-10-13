import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'expense_image.dart';
import 'favorite_button.dart';

/// Row in the "Последние траты" list: photo, title, day · category,
/// amount and a favorite toggle.
class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final bool isFavorite;
  final ValueChanged<bool> onFavoriteChanged;
  final VoidCallback onTap;

  const ExpenseTile({
    super.key,
    required this.expense,
    required this.isFavorite,
    required this.onFavoriteChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox.square(
                  dimension: 52,
                  child: ExpenseImage(expense: expense),
                ),
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
                    const SizedBox(height: 4),
                    Text(
                      '${Format.relativeDay(expense.date)} · '
                      '${expense.category.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
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
      ),
    );
  }
}
