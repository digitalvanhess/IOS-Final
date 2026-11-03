import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/planned_purchase.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/purchase_tile.dart';

/// «Корзина»: items picked in the catalog, the total in ₸ and «Очистить
/// всё». Every change goes through the global [CartProvider], so the
/// catalog switches and the badge update right away.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  void _remove(BuildContext context, PlannedPurchase item) {
    final cart = context.read<CartProvider>();
    final index = cart.remove(item);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('«${item.title}» убран из корзины'),
          action: SnackBarAction(
            label: 'Отменить',
            textColor: AppColors.accent,
            onPressed: () => cart.add(item, index: index),
          ),
        ),
      );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Очистить корзину?'),
        content: const Text('Все выбранные покупки будут убраны.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<CartProvider>().clear();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Корзина'),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Очистить всё'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: items.isEmpty
          ? const _EmptyState()
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return PurchaseTile(
                        key: ValueKey(item.id),
                        item: item,
                        trailing: IconButton(
                          onPressed: () => _remove(context, item),
                          tooltip: 'Убрать',
                          color: AppColors.textSecondary,
                          icon: const Icon(Icons.delete_outline),
                        ),
                      );
                    },
                  ),
                ),
                _TotalBar(count: cart.count, total: cart.totalPrice),
              ],
            ),
    );
  }
}

class _TotalBar extends StatelessWidget {
  final int count;
  final int total;

  const _TotalBar({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Итого · $count ${Format.purchasesWord(count)}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              Text(
                Format.money(total),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'Корзина пуста',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Включите «В корзину» у покупок в каталоге, '
              'и здесь появится итоговая сумма.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('К покупкам'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
