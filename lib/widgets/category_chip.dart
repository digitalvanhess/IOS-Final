import 'package:flutter/material.dart';

import '../models/category.dart';
import '../theme/app_theme.dart';

/// Rounded chip with a category icon; highlighted when selected.
class CategoryChip extends StatelessWidget {
  final ExpenseCategory category;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 16,
              color: selected ? AppColors.accent : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              category.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
