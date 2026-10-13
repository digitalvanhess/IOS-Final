import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/expense_image.dart';
import '../widgets/favorite_button.dart';
import '../widgets/tag_chip.dart';

/// Detail screen. Receives the complete [Expense] through Navigator.push
/// and goes back with Navigator.pop from the AppBar back icon or the
/// in-body button. Pops with `true` when the user deletes the expense.
class ExpenseDetailScreen extends StatefulWidget {
  final Expense expense;
  final int dailyLimit;
  final bool isFavorite;
  final ValueChanged<bool> onFavoriteChanged;

  const ExpenseDetailScreen({
    super.key,
    required this.expense,
    required this.dailyLimit,
    required this.isFavorite,
    required this.onFavoriteChanged,
  });

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  late bool _isFavorite = widget.isFavorite;

  void _onFavoriteChanged(bool value) {
    setState(() => _isFavorite = value);
    widget.onFavoriteChanged(value);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Удалить трату?'),
        content: Text(widget.expense.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final expense = widget.expense;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          tooltip: 'Назад',
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Трата'),
        actions: [
          FavoriteButton(
            isFavorite: _isFavorite,
            onChanged: _onFavoriteChanged,
            size: 26,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final info = _Info(
              expense: expense,
              dailyLimit: widget.dailyLimit,
              onBack: () => Navigator.pop(context),
              onDelete: _confirmDelete,
            );

            // Wide screens: banner and info side by side.
            if (constraints.maxWidth >= 700) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _Banner(expense: expense, height: 380),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(0, 20, 20, 20),
                      child: info,
                    ),
                  ),
                ],
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Banner(expense: expense, height: 260),
                  const SizedBox(height: 20),
                  info,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Photo with a gradient, a category badge and the amount overlaid.
class _Banner extends StatelessWidget {
  final Expense expense;
  final double height;

  const _Banner({required this.expense, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExpenseImage(expense: expense, iconSize: 72),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33000000), Color(0xE6000000)],
                  stops: [0.35, 1],
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: expense.category.color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(expense.category.icon, size: 14, color: Colors.black),
                    const SizedBox(width: 6),
                    Text(
                      expense.category.label,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      Format.money(-expense.amount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                      ),
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

class _Info extends StatelessWidget {
  final Expense expense;
  final int dailyLimit;
  final VoidCallback onBack;
  final VoidCallback onDelete;

  const _Info({
    required this.expense,
    required this.dailyLimit,
    required this.onBack,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final share = dailyLimit <= 0 ? 0.0 : expense.amount / dailyLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TagChip(
              icon: Icons.event_outlined,
              label: Format.relativeDay(expense.date),
            ),
            TagChip(icon: Icons.schedule, label: Format.time(expense.date)),
            if (expense.place.isNotEmpty)
              TagChip(icon: Icons.place_outlined, label: expense.place),
            for (final tag in expense.tags)
              if (tag != expense.category.label) TagChip(label: '#$tag'),
          ],
        ),
        const SizedBox(height: 20),
        _Panel(
          title: 'Доля дневного лимита',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: share.clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: AppColors.cardLight,
                  color: share > 1 ? AppColors.danger : AppColors.accent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(share * 100).round()}% от ${Format.money(dailyLimit)} в день',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (expense.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Panel(
            title: 'Комментарий',
            child: Text(
              expense.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('К тратам'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Удалить'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  backgroundColor: AppColors.dangerSoft,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final Widget child;

  const _Panel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
