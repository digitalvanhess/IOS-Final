import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/app_theme.dart';
import '../bloc/cart/cart_bloc.dart';

/// AppBar cart icon with a live [Badge].
///
/// [BlocBuilder] with `buildWhen`: only this icon rebuilds, and only when
/// [CartState.count] changes. The same widget sits on the catalog and on
/// the cart screen, two separate routes, and both read one [CartBloc]
/// provided above `MaterialApp`, so they always show the same number.
class CartBadgeAction extends StatelessWidget {
  final VoidCallback? onPressed;

  const CartBadgeAction({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      buildWhen: (previous, current) => previous.count != current.count,
      builder: (context, state) {
        return IconButton(
          tooltip: 'Корзина',
          onPressed: onPressed,
          icon: Badge(
            key: const ValueKey('cart_badge'),
            isLabelVisible: state.count > 0,
            backgroundColor: context.palette.accent,
            textColor: Colors.black,
            label: Text('${state.count}'),
            child: const Icon(Icons.shopping_cart_outlined),
          ),
        );
      },
    );
  }
}
