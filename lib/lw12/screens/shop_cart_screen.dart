import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../bloc/cart/cart_bloc.dart';
import '../data/shop_catalog.dart';
import '../widgets/cart_badge_action.dart';

/// Screen 3 (LW12): cart lines, [RemoveProductEvent] per line, total and
/// «Очистить всё» ([ClearCartEvent]). Pure [BlocBuilder]: no local state.
class ShopCartScreen extends StatelessWidget {
  const ShopCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Корзина'),
        actions: const [CartBadgeAction(), SizedBox(width: 8)],
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state.isEmpty) return const _EmptyCart();
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: state.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _CartLine(item: state.items[index]),
                ),
              ),
              _Summary(state: state),
            ],
          );
        },
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  final CartItem item;

  const _CartLine({required this.item});

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    return Card(
      key: ValueKey('cart_line_${product.id}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Row(
          children: [
            Icon(ShopCatalog.iconFor(product), color: AppColors.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.quantity} × ${Format.money(product.price)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              Format.money(item.lineTotal),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            IconButton(
              key: ValueKey('remove_${product.id}'),
              tooltip: 'Убрать',
              color: AppColors.textSecondary,
              onPressed: () =>
                  context.read<CartBloc>().add(RemoveProductEvent(product.id)),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final CartState state;

  const _Summary({required this.state});

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Итого · ${state.count} ${Format.purchasesWord(state.count)}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  Text(
                    Format.money(state.totalPrice),
                    key: const ValueKey('cart_total'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const ValueKey('clear_cart'),
                  onPressed: () =>
                      context.read<CartBloc>().add(const ClearCartEvent()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('Очистить всё'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

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
              'Нажмите «Добавить» у товара в магазине.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('В магазин'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
