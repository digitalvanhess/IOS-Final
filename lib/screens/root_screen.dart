import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'add_expense_screen.dart';
import 'expense_detail_screen.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'overview_screen.dart';
import 'profile_screen.dart';
import 'today_screen.dart';

/// App shell with the BottomNavigationBar.
///
/// Owns the shared state: expenses, favorites and the selected tab. Tabs
/// live in an IndexedStack, so switching tabs or coming back from a pushed
/// screen keeps their scroll position and local state.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  /// Index of the "+" item in the bar. It opens a screen instead of a tab.
  static const _addItemIndex = 2;

  final Budget _budget = MockData.budget();
  final List<Expense> _expenses = MockData.expenses();
  final Set<String> _favoriteIds = {'e2'};
  int _tab = 0;

  List<Expense> get _sortedExpenses =>
      [..._expenses]..sort((a, b) => b.date.compareTo(a.date));

  List<Expense> get _favorites =>
      _sortedExpenses.where((e) => _favoriteIds.contains(e.id)).toList();

  bool _isFavorite(Expense e) => _favoriteIds.contains(e.id);

  void _setFavorite(Expense e, bool value) {
    setState(() => value ? _favoriteIds.add(e.id) : _favoriteIds.remove(e.id));
  }

  void _deleteExpense(Expense e) {
    final index = _expenses.indexOf(e);
    setState(() {
      _expenses.remove(e);
      _favoriteIds.remove(e.id);
    });
    _showSnack(
      'Трата удалена',
      onUndo: () {
        setState(() => _expenses.insert(index.clamp(0, _expenses.length), e));
      },
    );
  }

  /// Navigator.push with arguments: the whole [Expense] goes to the detail
  /// screen. It pops back with `true` when the user deletes the expense.
  Future<void> _openDetail(Expense expense) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseDetailScreen(
          expense: expense,
          dailyLimit: _budget.dailyLimit(DateTime.now()),
          isFavorite: _isFavorite(expense),
          onFavoriteChanged: (v) => _setFavorite(expense, v),
        ),
      ),
    );
    if (deleted == true && mounted) _deleteExpense(expense);
  }

  /// "Все траты" (list / grid). Changes made there come back through the
  /// callbacks, so the feed, overview and favorites update too.
  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryScreen(
          expenses: _sortedExpenses,
          dailyLimit: _budget.dailyLimit(DateTime.now()),
          isFavorite: _isFavorite,
          onFavoriteChanged: _setFavorite,
          onAdded: (e) => setState(() => _expenses.add(e)),
          onRemoved: (e) => setState(() {
            _expenses.remove(e);
            _favoriteIds.remove(e.id);
          }),
          onReset: (seed) => setState(
            () => _expenses
              ..clear()
              ..addAll(seed),
          ),
        ),
      ),
    );
  }

  /// The add screen pops with the new [Expense] (or null when closed).
  Future<void> _openAddExpense() async {
    final now = DateTime.now();
    final created = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            AddExpenseScreen(leftToday: _budget.leftToday(_expenses, now)),
      ),
    );
    if (created == null || !mounted) return;

    setState(() {
      _expenses.add(created);
      _tab = 0;
    });
    _showSnack(
      'Расход сохранён · ${created.title} ${Format.money(-created.amount)}',
      onUndo: () => setState(() => _expenses.remove(created)),
    );
  }

  void _showSnack(String text, {required VoidCallback onUndo}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          action: SnackBarAction(
            label: 'Отменить',
            textColor: AppColors.accent,
            onPressed: onUndo,
          ),
        ),
      );
  }

  void _onNavTap(int index) {
    if (index == _addItemIndex) {
      _openAddExpense();
      return;
    }
    setState(() => _tab = index > _addItemIndex ? index - 1 : index);
  }

  int get _navIndex => _tab >= _addItemIndex ? _tab + 1 : _tab;

  @override
  Widget build(BuildContext context) {
    final expenses = _sortedExpenses;

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          TodayScreen(
            budget: _budget,
            expenses: expenses,
            isFavorite: _isFavorite,
            onFavoriteChanged: _setFavorite,
            onExpenseTap: _openDetail,
            onAddTap: _openAddExpense,
            onHistoryTap: _openHistory,
          ),
          OverviewScreen(expenses: expenses),
          FavoritesScreen(
            favorites: _favorites,
            onFavoriteChanged: _setFavorite,
            onExpenseTap: _openDetail,
            onBrowse: () => setState(() => _tab = 0),
          ),
          ProfileScreen(
            budget: _budget,
            expensesCount: _expenses.length,
            favoritesCount: _favoriteIds.length,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Сегодня',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            activeIcon: Icon(Icons.pie_chart),
            label: 'Обзор',
          ),
          BottomNavigationBarItem(
            icon: _AddButton(),
            label: '',
            tooltip: 'Новый расход',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_outline_rounded),
            activeIcon: Icon(Icons.star_rounded),
            label: 'Избранное',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

/// Lime "+" circle in the middle of the bar, as in the mockup.
class _AddButton extends StatelessWidget {
  const _AddButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.add, color: Colors.black, size: 28),
    );
  }
}
