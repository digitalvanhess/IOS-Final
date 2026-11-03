import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

/// Cart icon with a live lime badge. Uses `context.select`, so only this
/// button rebuilds when the number of items changes, not the whole AppBar.
class CartBadgeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CartBadgeButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final count = context.select<CartProvider, int>((cart) => cart.count);

    return IconButton(
      onPressed: onPressed,
      tooltip: 'Корзина',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.shopping_cart_outlined),
          // Always in the tree, so the 0 → 1 change animates too.
          Positioned(top: -6, right: -8, child: _CountBadge(count: count)),
        ],
      ),
    );
  }
}

/// Pill with the count, hidden at 0. Pops (scale 1 → 1.35 → 1) every time
/// the count changes.
class _CountBadge extends StatefulWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  State<_CountBadge> createState() => _CountBadgeState();
}

class _CountBadgeState extends State<_CountBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final Animation<double> _scale = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void didUpdateWidget(_CountBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count == 0) return const SizedBox.shrink();
    return ScaleTransition(
      scale: _scale,
      child: Container(
        constraints: const BoxConstraints(minWidth: 18),
        height: 18,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.background, width: 1.5),
        ),
        child: Text(
          '${widget.count}',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
