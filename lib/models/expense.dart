import 'category.dart';

/// One spending record. Passed as a whole object to the detail screen.
class Expense {
  final String id;
  final String title;
  final String description;
  final int amount;
  final ExpenseCategory category;
  final DateTime date;
  final String place;
  final String imageUrl;
  final List<String> tags;

  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.description = '',
    this.place = '',
    this.imageUrl = '',
    this.tags = const [],
  });

  bool get hasImage => imageUrl.isNotEmpty;
}
