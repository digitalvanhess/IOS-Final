import 'package:flutter/foundation.dart';

import '../models/planned_purchase.dart';

/// Global cart shared by the «Покупки» catalog and the «Корзина» screen.
///
/// Lives above MaterialApp, so every route reads the same instance and a
/// change on one screen rebuilds the listeners on all of them.
class CartProvider extends ChangeNotifier {
  final List<PlannedPurchase> _items = [];

  List<PlannedPurchase> get items => List.unmodifiable(_items);

  int get count => _items.length;

  bool get isEmpty => _items.isEmpty;

  int get totalPrice => _items.fold(0, (sum, item) => sum + item.price);

  bool isInCart(PlannedPurchase item) => _items.any((e) => e.id == item.id);

  /// Adds [item] once. [index] puts it back at its old place (used by UNDO).
  void add(PlannedPurchase item, {int? index}) {
    if (isInCart(item)) return;
    if (index == null) {
      _items.add(item);
    } else {
      _items.insert(index.clamp(0, _items.length), item);
    }
    notifyListeners();
  }

  /// Removes [item] and returns its index, or -1 if it was not in the cart.
  int remove(PlannedPurchase item) {
    final index = _items.indexWhere((e) => e.id == item.id);
    if (index == -1) return -1;
    _items.removeAt(index);
    notifyListeners();
    return index;
  }

  void toggle(PlannedPurchase item) {
    isInCart(item) ? remove(item) : add(item);
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}
