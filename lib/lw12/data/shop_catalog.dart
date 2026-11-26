import 'package:flutter/material.dart';

import '../models/product.dart';

/// Offline demo catalog for LW12 (prices in ₸). No network, so the lab
/// works the same in class, on the simulator and in tests.
class ShopCatalog {
  static const products = <Product>[
    Product(
      id: 'p1',
      title: 'Беспроводные наушники',
      subtitle: 'Для пар онлайн и спортзала',
      price: 14990,
    ),
    Product(
      id: 'p2',
      title: 'Рюкзак для ноутбука',
      subtitle: '15,6″, водоотталкивающий',
      price: 18500,
    ),
    Product(
      id: 'p3',
      title: 'Термокружка',
      subtitle: '450 мл, держит тепло 6 часов',
      price: 5900,
    ),
    Product(
      id: 'p4',
      title: 'Powerbank 10 000 мАч',
      subtitle: 'Быстрая зарядка USB-C',
      price: 9990,
    ),
    Product(
      id: 'p5',
      title: 'Набор тетрадей',
      subtitle: '5 штук, клетка, А5',
      price: 2400,
    ),
    Product(
      id: 'p6',
      title: 'Флешка 64 ГБ',
      subtitle: 'Для курсовых и презентаций',
      price: 3500,
    ),
  ];

  static const _icons = {
    'p1': Icons.headphones,
    'p2': Icons.backpack_outlined,
    'p3': Icons.coffee_outlined,
    'p4': Icons.battery_charging_full,
    'p5': Icons.menu_book_outlined,
    'p6': Icons.usb,
  };

  /// UI detail, kept out of the model so [Product] stays a pure value.
  static IconData iconFor(Product product) =>
      _icons[product.id] ?? Icons.shopping_bag_outlined;
}
