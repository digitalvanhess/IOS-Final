import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../widgets/expense_grid_card.dart';
import '../widgets/expense_list_row.dart';
import 'expense_detail_screen.dart';

/// "Все траты": every expense as a list or a 2-column grid.
///
/// Gestures: pull down to "load" a new expense, swipe left to delete it
/// (with UNDO in the SnackBar). The screen keeps its own copy of the list
/// so it can insert and remove by index, and reports every change to
/// [RootScreen] through the callbacks so the other tabs stay in sync.
class HistoryScreen extends StatefulWidget {
  final List<Expense> expenses;
  final int dailyLimit;
  final bool Function(Expense) isFavorite;
  final void Function(Expense, bool) onFavoriteChanged;
  final ValueChanged<Expense> onAdded;
  final ValueChanged<Expense> onRemoved;
  final ValueChanged<List<Expense>> onReset;

  const HistoryScreen({
    super.key,
    required this.expenses,
    required this.dailyLimit,
    required this.isFavorite,
    required this.onFavoriteChanged,
    required this.onAdded,
    required this.onRemoved,
    required this.onReset,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final List<Expense> _items = [...widget.expenses];
  bool _isGrid = false;

  /// Pull-to-refresh: fake a 1.5 s network request, then put the new
  /// expense at the very top of the list.
  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    final fresh = MockData.randomExpense();
    setState(() => _items.insert(0, fresh));
    widget.onAdded(fresh);
  }

  /// Removes the item and offers UNDO, which puts it back at [index].
  void _remove(int index) {
    final removed = _items[index];
    setState(() => _items.removeAt(index));
    widget.onRemoved(removed);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('«${removed.title}» удалено'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'ОТМЕНИТЬ',
            textColor: AppColors.accent,
            onPressed: () => _restore(index, removed),
          ),
        ),
      );
  }

  void _restore(int index, Expense expense) {
    widget.onAdded(expense);
    // The SnackBar can outlive this screen; RootScreen still gets it back.
    if (!mounted) return;
    setState(() => _items.insert(index.clamp(0, _items.length), expense));
  }

  void _resetCatalog() {
    final seed = MockData.expenses()..sort((a, b) => b.date.compareTo(a.date));
    setState(() => _items.addAll(seed));
    widget.onReset(seed);
  }

  Future<void> _openDetail(Expense expense) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseDetailScreen(
          expense: expense,
          dailyLimit: widget.dailyLimit,
          isFavorite: widget.isFavorite(expense),
          onFavoriteChanged: (v) => widget.onFavoriteChanged(expense, v),
        ),
      ),
    );
    if (!mounted) return;
    // Rebuild so the stars reflect a change made on the detail screen.
    setState(() {});
    final index = _items.indexOf(expense);
    if (deleted == true && index != -1) _remove(index);
  }

  /// Wraps an item so it can be swiped right-to-left to delete. The
  /// ValueKey tells Flutter which item left, so the rest keep their state.
  Widget _dismissible(int index, Widget child) {
    final expense = _items[index];
    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: const _DeleteBackground(),
      onDismissed: (_) => _remove(index),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Все траты'),
        actions: [
          IconButton(
            tooltip: _isGrid ? 'Списком' : 'Сеткой',
            onPressed: () => setState(() => _isGrid = !_isGrid),
            icon: Icon(
              _isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.accent,
        backgroundColor: AppColors.card,
        child: _items.isEmpty
            ? _EmptyCatalog(onReset: _resetCatalog)
            : _isGrid
            ? _buildGrid()
            : _buildList(),
      ),
    );
  }

  /// Lazy list: only the rows on screen are built.
  Widget _buildList() {
    return ListView.separated(
      key: const PageStorageKey('history-list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const Divider(
        height: 1,
        thickness: 0.5,
        indent: 76,
        color: AppColors.border,
      ),
      itemBuilder: (context, index) {
        final expense = _items[index];
        return _dismissible(
          index,
          ExpenseListRow(
            expense: expense,
            isFavorite: widget.isFavorite(expense),
            onFavoriteChanged: (v) => widget.onFavoriteChanged(expense, v),
            onTap: () => _openDetail(expense),
          ),
        );
      },
    );
  }

  /// Lazy 2-column grid. childAspectRatio 0.72 makes cells taller than
  /// wide, leaving room for the photo and three lines of text.
  Widget _buildGrid() {
    return GridView.builder(
      key: const PageStorageKey('history-grid'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final expense = _items[index];
        return _dismissible(
          index,
          ExpenseGridCard(
            expense: expense,
            isFavorite: widget.isFavorite(expense),
            onFavoriteChanged: (v) => widget.onFavoriteChanged(expense, v),
            onTap: () => _openDetail(expense),
          ),
        );
      },
    );
  }
}

/// Red background revealed under an item while it is swiped.
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }
}

/// Shown when every item was swiped away. Still scrollable, so
/// pull-to-refresh keeps working on an empty screen.
class _EmptyCatalog extends StatelessWidget {
  final VoidCallback onReset;

  const _EmptyCatalog({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 16),
              const Text(
                'Catalog is Empty',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Все траты удалены. Верните демо-данные или потяните вниз, '
                'чтобы загрузить новую.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 220,
                child: ElevatedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset Catalog'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
