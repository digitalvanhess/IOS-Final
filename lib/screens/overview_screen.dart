import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

enum _Period { week, month }

/// "Обзор": spending by category for the selected period.
class OverviewScreen extends StatefulWidget {
  final List<Expense> expenses;

  const OverviewScreen({super.key, required this.expenses});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  _Period _period = _Period.week;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = _period == _Period.week ? 7 : 30;
    final from = DateTime(now.year, now.month, now.day - days + 1);
    final inPeriod = widget.expenses
        .where((e) => !e.date.isBefore(from))
        .toList();
    final total = inPeriod.fold<int>(0, (sum, e) => sum + e.amount);

    final byCategory = <ExpenseCategory, int>{};
    for (final e in inPeriod) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }
    final rows = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Обзор')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          SegmentedButton<_Period>(
            segments: const [
              ButtonSegment(value: _Period.week, label: Text('Неделя')),
              ButtonSegment(value: _Period.month, label: Text('Месяц')),
            ],
            selected: {_period},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _period = s.first),
            style: SegmentedButton.styleFrom(
              backgroundColor: AppColors.card,
              selectedBackgroundColor: AppColors.accent,
              selectedForegroundColor: Colors.black,
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Потрачено за $days ${_daysWord(days)}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Format.money(total),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${inPeriod.length} ${_purchasesWord(inPeriod.length)} · '
                  'в среднем ${Format.money(total / days)} в день',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(
                child: Text(
                  'За этот период трат нет',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            for (final row in rows)
              _CategoryRow(
                category: row.key,
                amount: row.value,
                share: total == 0 ? 0 : row.value / total,
              ),
        ],
      ),
    );
  }

  String _daysWord(int n) => Format.daysWord(n);

  String _purchasesWord(int n) {
    final mod10 = n % 10;
    final mod100 = n % 100;
    if (mod10 == 1 && mod100 != 11) return 'трата';
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return 'траты';
    }
    return 'трат';
  }
}

class _CategoryRow extends StatelessWidget {
  final ExpenseCategory category;
  final int amount;
  final double share;

  const _CategoryRow({
    required this.category,
    required this.amount,
    required this.share,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(category.icon, size: 20, color: category.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      Format.money(amount),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: share,
                    minHeight: 6,
                    backgroundColor: AppColors.cardLight,
                    color: category.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text(
              '${(share * 100).round()}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
