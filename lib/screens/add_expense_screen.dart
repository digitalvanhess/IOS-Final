import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/category_chip.dart';
import '../widgets/keypad.dart';

/// "Новый расход": amount keypad + category chips. Pops with the created
/// [Expense] so RootScreen can add it to the list.
class AddExpenseScreen extends StatefulWidget {
  /// How much is still left for today, to warn before overspending.
  final int leftToday;

  const AddExpenseScreen({super.key, required this.leftToday});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  static const _maxDigits = 7;

  String _digits = '';
  ExpenseCategory _category = ExpenseCategory.food;
  final _titleController = TextEditingController();

  int get _amount => int.tryParse(_digits) ?? 0;
  int get _leftAfter => widget.leftToday - _amount;
  bool get _overLimit => _amount > 0 && _leftAfter < 0;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _onKey(String key) {
    final next = _digits + key;
    if (next.length > _maxDigits) return;
    setState(() => _digits = next.replaceFirst(RegExp(r'^0+'), ''));
  }

  void _onBackspace() {
    if (_digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  void _save() {
    final title = _titleController.text.trim();
    Navigator.pop(
      context,
      Expense(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title.isEmpty ? _category.label : title,
        amount: _amount,
        category: _category,
        date: DateTime.now(),
        tags: [_category.label],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Закрыть',
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Новый расход'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _AmountDisplay(amount: _amount, overLimit: _overLimit),
                    const SizedBox(height: 4),
                    const Text(
                      'Сколько потратили?',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final c in ExpenseCategory.values)
                          CategoryChip(
                            category: c,
                            selected: c == _category,
                            onTap: () => setState(() => _category = c),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Комментарий (необязательно)',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Hint(amount: _amount, leftAfter: _leftAfter),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                children: [
                  Keypad(onKey: _onKey, onBackspace: _onBackspace),
                  const SizedBox(height: 4),
                  ElevatedButton(
                    onPressed: _amount == 0 ? null : _save,
                    style: _overLimit
                        ? ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                            foregroundColor: Colors.white,
                          )
                        : null,
                    child: Text(
                      _overLimit ? 'Всё равно сохранить' : 'Сохранить расход',
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

class _AmountDisplay extends StatelessWidget {
  final int amount;
  final bool overLimit;

  const _AmountDisplay({required this.amount, required this.overLimit});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: FittedBox(
        child: Text(
          Format.money(amount),
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.5,
            color: amount == 0
                ? AppColors.textMuted
                : (overLimit ? AppColors.danger : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Live hint under the amount: how much is left today after this expense.
class _Hint extends StatelessWidget {
  final int amount;
  final int leftAfter;

  const _Hint({required this.amount, required this.leftAfter});

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color color;
    final Color background;
    if (amount == 0) {
      text = 'Введите сумму — сразу покажем, сколько останется на сегодня';
      color = AppColors.textSecondary;
      background = AppColors.card;
    } else if (leftAfter >= 0) {
      text = 'После этой траты на сегодня останется ${Format.money(leftAfter)}';
      color = AppColors.accent;
      background = AppColors.accentSoft;
    } else {
      text =
          'Это больше дневного лимита на ${Format.money(-leftAfter)}. '
          'Завтрашний лимит станет меньше.';
      color = AppColors.danger;
      background = AppColors.dangerSoft;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: color, height: 1.4),
      ),
    );
  }
}
