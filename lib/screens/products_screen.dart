import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_api.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/cart_badge_button.dart';
import '../widgets/product_image.dart';
import '../widgets/rating_stars.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';

/// The three production UI states of the feed.
enum LoadState { loading, success, error }

/// «Онлайн-магазин» (LW10): products from https://fakestoreapi.com.
///
/// Loading → spinner, success → `ListView.separated` with pull-to-refresh,
/// error → offline screen with «Повторить». Prices are shown in ₸ like the
/// rest of Stipa, with the original USD price next to them.
class ProductsScreen extends StatefulWidget {
  /// Injected in tests (MockClient). Real app: default [ProductApi].
  final ProductApi? api;

  const ProductsScreen({super.key, this.api});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final ProductApi _api = widget.api ?? ProductApi();

  LoadState _state = LoadState.loading;
  List<Product> _products = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// First load and «Повторить»: shows the spinner, then the list or the
  /// error screen. No app restart needed.
  Future<void> _load() async {
    setState(() => _state = LoadState.loading);
    try {
      final products = await _api.fetchProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _state = LoadState.success;
      });
    } on ProductApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _state = LoadState.error;
      });
    }
  }

  /// Pull-to-refresh: keeps the current list on screen. If the refresh
  /// fails, the old data stays and a SnackBar explains why.
  Future<void> _refresh() async {
    try {
      final products = await _api.fetchProducts();
      if (!mounted) return;
      setState(() => _products = products);
    } on ProductApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _openDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Онлайн-магазин'),
        actions: [
          CartBadgeButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: switch (_state) {
        LoadState.loading => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        LoadState.error => _ErrorState(message: _error, onRetry: _load),
        LoadState.success => _buildFeed(),
      },
    );
  }

  Widget _buildFeed() {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: Colors.black,
      backgroundColor: AppColors.accent,
      child: ListView.separated(
        // Pull-to-refresh works even when the list is short.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: _products.length + 1,
        separatorBuilder: (_, index) => index == 0
            ? const SizedBox(height: 4)
            : const Divider(height: 1, thickness: 0.5),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Text(
              '${_products.length} товаров · цены в ₸ по курсу '
              '1 \$ = ${Product.usdToKzt} ₸',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            );
          }
          final product = _products[index - 1];
          return _ProductRow(
            product: product,
            onTap: () => _openDetail(product),
          );
        },
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductRow({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              // Same tag as the first carousel photo on the detail screen.
              child: Hero(
                tag: 'product_image_${product.id}',
                child: ProductImage(url: product.imageUrl),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RatingStars(
                    rating: product.rating,
                    reviewCount: product.reviewCount,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          Format.money(product.priceKzt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Format.usd(product.price),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Offline / timeout / server error with a working «Повторить» button.
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.dangerSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Нет связи с магазином',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 240,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
