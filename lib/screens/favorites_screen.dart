import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../widgets/expense_tile.dart';

/// Tab "Избранное": expenses the user starred (e.g. regular purchases).
class FavoritesScreen extends StatelessWidget {
  final List<Expense> favorites;
  final void Function(Expense, bool) onFavoriteChanged;
  final ValueChanged<Expense> onExpenseTap;
  final VoidCallback onBrowse;

  const FavoritesScreen({
    super.key,
    required this.favorites,
    required this.onFavoriteChanged,
    required this.onExpenseTap,
    required this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: favorites.isEmpty
          ? _EmptyState(onBrowse: onBrowse)
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: favorites.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final expense = favorites[index];
                return ExpenseTile(
                  expense: expense,
                  isFavorite: true,
                  onFavoriteChanged: (v) => onFavoriteChanged(expense, v),
                  onTap: () => onExpenseTap(expense),
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onBrowse;

  const _EmptyState({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_outline_rounded,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'Здесь пока пусто',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Отмечайте звёздочкой частые траты, чтобы быстро находить их.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: onBrowse,
                child: const Text('К тратам'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
