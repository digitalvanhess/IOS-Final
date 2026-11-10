import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/planned_purchase.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/cart_badge_button.dart';
import '../widgets/product_image.dart';
import '../widgets/rating_stars.dart';
import 'cart_screen.dart';

/// Product page (LW10): Hero photo, swipeable carousel with dots and a
/// «1 / 3» counter, category badge, full description, sticky «В корзину»
/// button wired to the global [CartProvider] from LW9, and a share sheet
/// with the deep link.
class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _pageController = PageController();
  int _page = 0;

  Product get _product => widget.product;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    );
  }

  void _addToCart() {
    context.read<CartProvider>().add(PlannedPurchase.fromProduct(_product));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Добавлено в корзину'),
          action: SnackBarAction(
            label: 'Открыть',
            textColor: AppColors.accent,
            onPressed: _openCart,
          ),
        ),
      );
  }

  void _share() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ShareSheet(
        link: _product.deepLink,
        onCopied: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Ссылка скопирована')));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    final images = product.gallery;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Товар'),
        actions: [
          IconButton(
            onPressed: _share,
            tooltip: 'Поделиться',
            icon: const Icon(Icons.ios_share),
          ),
          CartBadgeButton(onPressed: _openCart),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  // Keeps the photo and text readable on iPad.
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Carousel(
                        productId: product.id,
                        images: images,
                        controller: _pageController,
                        page: _page,
                        onPageChanged: (i) => setState(() => _page = i),
                      ),
                      const SizedBox(height: 12),
                      _Dots(count: images.length, active: _page),
                      const SizedBox(height: 20),
                      _CategoryBadge(label: product.categoryLabel),
                      const SizedBox(height: 12),
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      RatingStars(
                        rating: product.rating,
                        reviewCount: product.reviewCount,
                        size: 16,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.end,
                        spacing: 10,
                        children: [
                          Text(
                            Format.money(product.priceKzt),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Text(
                              '${Format.usd(product.price)} · '
                              '1 \$ = ${Product.usdToKzt} ₸',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Описание',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description.isEmpty
                            ? 'Описание не указано.'
                            : product.description,
                        style: const TextStyle(
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _BottomBar(
            product: product,
            onAdd: _addToCart,
            onOpenCart: _openCart,
          ),
        ],
      ),
    );
  }
}

/// Swipeable photos. Only page 0 carries the Hero tag, so the thumbnail
/// from the feed flies exactly into the first photo.
class _Carousel extends StatelessWidget {
  final int productId;
  final List<String> images;
  final PageController controller;
  final int page;
  final ValueChanged<int> onPageChanged;

  const _Carousel({
    required this.productId,
    required this.images,
    required this.controller,
    required this.page,
    required this.onPageChanged,
  });

  /// Three framings of the single API photo: whole item, top, bottom.
  static const _framings = [
    (scale: 1.0, alignment: Alignment.center),
    (scale: 1.7, alignment: Alignment.topCenter),
    (scale: 1.7, alignment: Alignment.bottomCenter),
  ];

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          PageView.builder(
            controller: controller,
            itemCount: images.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final framing = _framings[index % _framings.length];
              final photo = ProductImage(
                url: images[index],
                radius: 24,
                padding: const EdgeInsets.all(28),
                scale: framing.scale,
                alignment: framing.alignment,
              );
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: index == 0
                    ? Hero(tag: 'product_image_$productId', child: photo)
                    : photo,
              );
            },
          ),
          Positioned(
            top: 12,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${page + 1} / ${images.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated dots: the active one stretches into a lime pill.
class _Dots extends StatelessWidget {
  final int count;
  final int active;

  const _Dots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            key: ValueKey('dot_$i'),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == active ? AppColors.accent : AppColors.cardLight,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;

  const _CategoryBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sell_outlined, size: 14, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sticky bottom «В корзину». Reads the cart with `context.select`, so it
/// switches to «В корзине» right away and stays in sync with the cart
/// screen.
class _BottomBar extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;
  final VoidCallback onOpenCart;

  const _BottomBar({
    required this.product,
    required this.onAdd,
    required this.onOpenCart,
  });

  @override
  Widget build(BuildContext context) {
    final item = PlannedPurchase.fromProduct(product);
    final inCart = context.select<CartProvider, bool>((c) => c.isInCart(item));

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: inCart
              ? OutlinedButton.icon(
                  onPressed: onOpenCart,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('В корзине · открыть'),
                )
              : ElevatedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text('В корзину · ${Format.money(product.priceKzt)}'),
                ),
        ),
      ),
    );
  }
}

/// Bottom sheet with the deep link and a copy button.
class _ShareSheet extends StatelessWidget {
  final String link;
  final VoidCallback onCopied;

  const _ShareSheet({required this.link, required this.onCopied});

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    Navigator.pop(context);
    onCopied();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Поделиться товаром',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ссылка откроет этот товар в приложении',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 18, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SelectableText(
                      link,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _copy(context),
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Копировать ссылку'),
            ),
          ],
        ),
      ),
    );
  }
}
