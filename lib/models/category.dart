import 'package:flutter/material.dart';

/// Expense categories shown as chips on the add screen and as icons in lists.
enum ExpenseCategory {
  food('Еда', Icons.restaurant, Color(0xFFA4C639)),
  groceries('Продукты', Icons.shopping_cart_outlined, Color(0xFF4FB6A0)),
  cafe('Кафе', Icons.local_cafe_outlined, Color(0xFFE0A84F)),
  transport('Транспорт', Icons.directions_bus_outlined, Color(0xFF5B8DEF)),
  leisure('Досуг', Icons.confirmation_number_outlined, Color(0xFFB57EDC)),
  other('Другое', Icons.more_horiz, Color(0xFF8A8A8A));

  final String label;
  final IconData icon;
  final Color color;

  const ExpenseCategory(this.label, this.icon, this.color);
}
