import 'package:flutter/material.dart';

import 'category.dart';

/// Something the student plans to buy from the stipend. Shown in the
/// «Покупки» catalog and can be put into the cart.
class PlannedPurchase {
  final String id;
  final String title;
  final String note;
  final int price;
  final ExpenseCategory category;
  final IconData icon;

  const PlannedPurchase({
    required this.id,
    required this.title,
    required this.price,
    required this.category,
    required this.icon,
    this.note = '',
  });
}
