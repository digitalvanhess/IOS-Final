part of 'cart_bloc.dart';

/// Everything the UI can ask the cart to do. Events are immutable value
/// objects too.
sealed class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

/// «Добавить» in the catalog. Adding the same product again raises its
/// quantity.
final class AddProductEvent extends CartEvent {
  final Product product;

  const AddProductEvent(this.product);

  @override
  List<Object?> get props => [product];
}

/// Trash icon in the cart: removes the whole line.
final class RemoveProductEvent extends CartEvent {
  final String productId;

  const RemoveProductEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

/// «Очистить всё».
final class ClearCartEvent extends CartEvent {
  const ClearCartEvent();
}
