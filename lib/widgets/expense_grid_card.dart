import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'category_tag.dart';
import 'expense_image.dart';
import 'favorite_button.dart';

/// Card for the grid mode of "Все траты". The photo takes the free space
/// (Expanded) and the text part has a fixed number of lines, so the card
/// fits any cell size of the grid without overflowing.
class ExpenseGridCard extends StatelessWidget {
  final Expense expense;
  final bool isFavorite;
  final ValueChanged<bool> onFavoriteChanged;
  final VoidCallback onTap;

  const ExpenseGridCard({
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ExpenseImage(expense: expense, iconSize: 36),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Color(0x99000000),
                        shape: BoxShape.circle,
                      ),
                      child: FavoriteButton(
                        isFavorite: isFavorite,
                        onChanged: onFavoriteChanged,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  CategoryTag(category: expense.category),
                  const SizedBox(height: 8),
                  Text(
                    Format.money(-expense.amount),
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
