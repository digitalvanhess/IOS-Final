part of 'cart_bloc.dart';

/// One cart line: a product and how many of it.
class CartItem extends Equatable {
  final Product product;
  final int quantity;

  const CartItem({required this.product, this.quantity = 1});

  int get lineTotal => product.price * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);

  @override
  List<Object?> get props => [product, quantity];
}

/// Immutable snapshot of the cart. Handlers never change it in place: they
/// build a new list and emit a new [CartState].
class CartState extends Equatable {
  final List<CartItem> items;

  /// Sum of all lines in ₸.
  final int totalPrice;

  /// Number of units (2 × headphones + 1 mug = 3). Shown on the badge.
  final int count;

  const CartState({this.items = const [], this.totalPrice = 0, this.count = 0});

  /// Derives [totalPrice] and [count] from [items], so they never drift.
  factory CartState.fromItems(List<CartItem> items) => CartState(
    items: List.unmodifiable(items),
    totalPrice: items.fold(0, (sum, i) => sum + i.lineTotal),
    count: items.fold(0, (sum, i) => sum + i.quantity),
  );

  bool get isEmpty => items.isEmpty;

  /// How many of [productId] are in the cart (0 if none).
  int quantityOf(String productId) {
    for (final item in items) {
      if (item.product.id == productId) return item.quantity;
    }
    return 0;
  }

  @override
  List<Object?> get props => [items, totalPrice, count];
}
