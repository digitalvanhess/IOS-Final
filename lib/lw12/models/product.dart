import 'package:equatable/equatable.dart';

/// Store item for the LW12 BLoC shop.
///
/// Separate from the LW10 `Product` (fakestoreapi) on purpose: this one is
/// local, priced in ₸ and extends [Equatable], so two products with the same
/// fields are equal (`==`) and the cart can compare them by value.
class Product extends Equatable {
  final String id;
  final String title;
  final String subtitle;

  /// Price in whole tenge.
  final int price;

  const Product({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
  });

  @override
  List<Object?> get props => [id, title, subtitle, price];
}
