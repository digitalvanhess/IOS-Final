import 'package:flutter/material.dart';

import 'category.dart';
import 'product.dart';

/// Something the student plans to buy from the stipend. Shown in the
/// «Покупки» catalog and can be put into the cart.
class PlannedPurchase {
  final String id;
  final String title;
  final String note;
  final int price;
  final ExpenseCategory category;
  final IconData icon;

  /// Photo from the online store (LW10). Local items use [icon] instead.
  final String? imageUrl;

  const PlannedPurchase({
    required this.id,
    required this.title,
    required this.price,
    required this.category,
    required this.icon,
    this.note = '',
    this.imageUrl,
  });

  /// A product from the online store as a cart item, price in ₸.
  factory PlannedPurchase.fromProduct(Product product) {
    return PlannedPurchase(
      id: 'store_${product.id}',
      title: product.title,
      note: 'Онлайн-магазин · ${product.categoryLabel}',
      price: product.priceKzt,
      category: ExpenseCategory.other,
      icon: Icons.storefront_outlined,
      imageUrl: product.imageUrl,
    );
  }
}
