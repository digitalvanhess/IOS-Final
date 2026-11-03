import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../models/planned_purchase.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/cart_badge_button.dart';
import '../widgets/purchase_tile.dart';
import 'cart_screen.dart';

/// «Покупки»: planned student purchases with a «В корзину» switch.
///
/// Holds no state of its own. Each row reads `isInCart` from the global
/// [CartProvider], so removing an item on [CartScreen] flips the switch
/// here as well.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  static const _items = MockData.plannedPurchases;

  void _openCart(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Покупки'),
        actions: [
          CartBadgeButton(onPressed: () => _openCart(context)),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: _items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                'Отметьте, что хотите купить со стипендии',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return _CatalogRow(item: _items[index - 1]);
        },
      ),
    );
  }
}

class _CatalogRow extends StatelessWidget {
  final PlannedPurchase item;

  const _CatalogRow({required this.item});

  @override
  Widget build(BuildContext context) {
    // Only this row rebuilds when its own item enters or leaves the cart.
    final inCart = context.select<CartProvider, bool>(
      (cart) => cart.isInCart(item),
    );

    return PurchaseTile(
      item: item,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: inCart,
            onChanged: (_) => context.read<CartProvider>().toggle(item),
          ),
          const Text(
            'В корзину',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
