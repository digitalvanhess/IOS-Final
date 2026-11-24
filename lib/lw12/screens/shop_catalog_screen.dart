import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../bloc/auth/auth_cubit.dart';
import '../bloc/cart/cart_bloc.dart';
import '../data/shop_catalog.dart';
import '../models/product.dart';
import '../widgets/cart_badge_action.dart';
import 'login_screen.dart';
import 'shop_cart_screen.dart';

/// Screen 2 (LW12): product list. «Добавить» dispatches [AddProductEvent];
/// the AppBar badge listens to [CartBloc] through [CartBadgeAction].
class ShopCatalogScreen extends StatelessWidget {
  const ShopCatalogScreen({super.key});

  void _openCart(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ShopCartScreen()),
    );
  }

  void _logout(BuildContext context) {
    context.read<CartBloc>().add(const ClearCartEvent());
    context.read<AuthCubit>().logout();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    // Read once: this screen is only reachable after AuthSuccess.
    final auth = context.read<AuthCubit>().state;
    final name = auth is AuthSuccess ? auth.username : 'Гость';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Магазин'),
        actions: [
          CartBadgeAction(onPressed: () => _openCart(context)),
          IconButton(
            tooltip: 'Выйти',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: ShopCatalog.products.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Привет, $name! Что берём со стипендии?',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return _ProductCard(product: ShopCatalog.products[index - 1]);
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                ShopCatalog.iconFor(product),
                color: AppColors.accent,
              ),
            ),
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
                  const SizedBox(height: 2),
                  Text(
                    product.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Format.money(product.price),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _AddButton(product: product),
          ],
        ),
      ),
    );
  }
}

/// «Добавить» + how many are already in the cart. [BlocSelector] picks one
/// int out of [CartState], so a card rebuilds only when ITS quantity
/// changes.
class _AddButton extends StatelessWidget {
  final Product product;

  const _AddButton({required this.product});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CartBloc, CartState, int>(
      selector: (state) => state.quantityOf(product.id),
      builder: (context, quantity) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              key: ValueKey('add_${product.id}'),
              onPressed: () =>
                  context.read<CartBloc>().add(AddProductEvent(product)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Добавить'),
            ),
            SizedBox(
              height: 16,
              child: quantity > 0
                  ? Text(
                      'в корзине: $quantity',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    )
                  : null,
            ),
          ],
        );
      },
    );
  }
}
