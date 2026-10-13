import 'package:flutter/material.dart';

import '../models/budget.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/budget_ring.dart';
import '../widgets/expense_tile.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';

/// Tab 1 (Feed): today's budget ring, stipend stats and recent expenses.
class TodayScreen extends StatefulWidget {
  final Budget budget;
  final List<Expense> expenses;
  final bool Function(Expense) isFavorite;
  final void Function(Expense, bool) onFavoriteChanged;
  final ValueChanged<Expense> onExpenseTap;
  final VoidCallback onAddTap;

  const TodayScreen({
    super.key,
    required this.budget,
    required this.expenses,
    required this.isFavorite,
    required this.onFavoriteChanged,
    required this.onExpenseTap,
    required this.onAddTap,
  });

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  static const _collapsedCount = 4;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final budget = widget.budget;
    final expenses = widget.expenses;
    final visible = _showAll
        ? expenses
        : expenses.take(_collapsedCount).toList();

    final summary = _BudgetCard(
      leftToday: budget.leftToday(expenses, now),
      dailyLimit: budget.dailyLimit(now),
      spentToday: budget.spentToday(expenses, now),
    );
    final daysLeft = budget.daysLeft(now);
    final stats = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatCard(
              icon: Icons.calendar_today_outlined,
              value: '$daysLeft ${Format.daysWord(daysLeft)}',
              caption:
                  'до стипендии · ${Format.dayMonth(budget.nextStipendDate)}',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              icon: Icons.account_balance_wallet_outlined,
              value: Format.money(budget.remaining(expenses, now)),
              caption: 'осталось на период',
            ),
          ),
        ],
      ),
    );

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(child: _TopBar(date: now)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Wide screens: ring card and stats side by side.
                  if (constraints.maxWidth >= 640) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: summary),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: stats),
                      ],
                    );
                  }
                  return Column(
                    children: [summary, const SizedBox(height: 12), stats],
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            sliver: SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Последние траты',
                trailing: expenses.length > _collapsedCount
                    ? TextButton(
                        onPressed: () => setState(() => _showAll = !_showAll),
                        child: Text(_showAll ? 'Свернуть' : 'Все'),
                      )
                    : null,
              ),
            ),
          ),
          if (expenses.isEmpty)
            SliverToBoxAdapter(child: _EmptyList(onAddTap: widget.onAddTap))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverList.separated(
                itemCount: visible.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final expense = visible[index];
                  return ExpenseTile(
                    expense: expense,
                    isFavorite: widget.isFavorite(expense),
                    onFavoriteChanged: (v) =>
                        widget.onFavoriteChanged(expense, v),
                    onTap: () => widget.onExpenseTap(expense),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final DateTime date;

  const _TopBar({required this.date});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'stipa',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                Format.shortDate(date),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Big card with the ring. The "spent today" pill is overlaid on the
/// bottom edge of the ring with a Stack.
class _BudgetCard extends StatelessWidget {
  final int leftToday;
  final int dailyLimit;
  final int spentToday;

  const _BudgetCard({
    required this.leftToday,
    required this.dailyLimit,
    required this.spentToday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Text(
            'Сегодня можно потратить',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.maxWidth.clamp(160.0, 240.0);
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: BudgetRing(
                      leftToday: leftToday,
                      dailyLimit: dailyLimit,
                      size: size,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Потрачено сегодня ${Format.money(spentToday)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  final VoidCallback onAddTap;

  const _EmptyList({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          const Text(
            'Пока нет трат',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          TextButton(onPressed: onAddTap, child: const Text('Добавить расход')),
        ],
      ),
    );
  }
}
