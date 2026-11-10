import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:stipa/models/product.dart';
import 'package:stipa/providers/cart_provider.dart';
import 'package:stipa/screens/cart_screen.dart';
import 'package:stipa/screens/product_detail_screen.dart';
import 'package:stipa/screens/products_screen.dart';
import 'package:stipa/services/product_api.dart';
import 'package:stipa/theme/app_theme.dart';
import 'package:stipa/utils/format.dart';

/// Two products like fakestoreapi returns them. Note `price: 22` (int)
/// and `rate: 4` (int): the model must not crash on them.
final _json = [
  {
    'id': 1,
    'title': 'Fjallraven Backpack',
    'price': 109.95,
    'description': 'Your perfect pack for everyday use.',
    'category': "men's clothing",
    'image': 'https://fakestoreapi.com/img/1.jpg',
    'rating': {'rate': 3.9, 'count': 120},
  },
  {
    'id': 2,
    'title': 'Mens Casual T-Shirt',
    'price': 22,
    'description': 'Slim-fitting style.',
    'category': 'electronics',
    'image': 'https://fakestoreapi.com/img/2.jpg',
    'rating': {'rate': 4, 'count': 259},
  },
];

http.Response _ok() => http.Response.bytes(
  utf8.encode(jsonEncode(_json)),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const _sizes = {
  'iPhone SE': Size(320, 568),
  'iPhone 15': Size(393, 852),
  'iPad': Size(820, 1180),
};

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  Size size = const Size(393, 852),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(theme: AppTheme.dark, home: home),
    ),
  );
}

void main() {
  group('Product.fromJson', () {
    test('parses int and double numbers safely', () {
      final products = _json.map(Product.fromJson).toList();
      expect(products[0].price, 109.95);
      expect(products[1].price, 22.0);
      expect(products[1].rating, 4.0);
      expect(products[0].reviewCount, 120);
      expect(products[0].imageUrl, 'https://fakestoreapi.com/img/1.jpg');
      expect(products[0].priceKzt, (109.95 * Product.usdToKzt).round());
    });

    test('falls back on missing and null fields', () {
      final p = Product.fromJson({'id': 7, 'title': null, 'rating': null});
      expect(p.id, 7);
      expect(p.title, 'Без названия');
      expect(p.price, 0);
      expect(p.description, '');
      expect(p.rating, 0);
      expect(p.reviewCount, 0);
      expect(p.deepLink, 'narxoz://store/product/7');
    });
  });

  group('ProductApi', () {
    test('maps 404, 500 and no network to friendly errors', () async {
      Future<String> errorFor(MockClient client) async {
        try {
          await ProductApi(client: client).fetchProducts();
          return 'no error';
        } on ProductApiException catch (e) {
          return e.message;
        }
      }

      expect(
        await errorFor(MockClient((_) async => http.Response('', 404))),
        contains('404'),
      );
      expect(
        await errorFor(MockClient((_) async => http.Response('', 500))),
        contains('500'),
      );
      expect(
        await errorFor(
          MockClient((_) async => throw http.ClientException('offline')),
        ),
        contains('Нет подключения'),
      );
    });
  });

  for (final entry in _sizes.entries) {
    testWidgets('loading → list → detail without overflow on ${entry.key}', (
      tester,
    ) async {
      final api = ProductApi(client: MockClient((_) async => _ok()));
      await _pump(tester, ProductsScreen(api: api), size: entry.value);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Fjallraven Backpack'), findsOneWidget);
      expect(find.text(Format.usd(22)), findsOneWidget);

      await tester.tap(find.text('Fjallraven Backpack'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(find.text('Мужская одежда'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('error screen, then Повторить loads the list', (tester) async {
    var fail = true;
    final api = ProductApi(
      client: MockClient((_) async {
        if (fail) throw http.ClientException('airplane mode');
        return _ok();
      }),
    );
    await _pump(tester, ProductsScreen(api: api));
    await tester.pumpAndSettle();

    expect(find.text('Нет связи с магазином'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.text('Mens Casual T-Shirt'), findsOneWidget);
  });

  testWidgets('pull-to-refresh reloads the feed', (tester) async {
    var calls = 0;
    final api = ProductApi(
      client: MockClient((_) async {
        calls++;
        return _ok();
      }),
    );
    await _pump(tester, ProductsScreen(api: api));
    await tester.pumpAndSettle();

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('carousel counter, dots, add to cart and share link', (
    tester,
  ) async {
    final product = Product.fromJson(_json[0]);
    await _pump(tester, ProductDetailScreen(product: product));
    await tester.pumpAndSettle();

    expect(find.text('1 / 3'), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    final dot = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('dot_1')),
    );
    expect(dot.constraints?.maxWidth, 22);

    // Sticky button goes through the global cart from LW9.
    await tester.tap(find.textContaining('В корзину'));
    await tester.pumpAndSettle();
    expect(find.text('В корзине · открыть'), findsOneWidget);
    final cart = Provider.of<CartProvider>(
      tester.element(find.byType(ProductDetailScreen)),
      listen: false,
    );
    expect(cart.count, 1);
    expect(cart.totalPrice, product.priceKzt);

    // Share sheet with the deep link + copy.
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    await tester.tap(find.byTooltip('Поделиться'));
    await tester.pumpAndSettle();
    expect(find.text('narxoz://store/product/1'), findsOneWidget);
    await tester.tap(find.text('Копировать ссылку'));
    await tester.pumpAndSettle();
    expect(copied, 'narxoz://store/product/1');
    expect(find.text('Ссылка скопирована'), findsOneWidget);

    // The badge in the AppBar opens the same cart.
    await tester.tap(find.byTooltip('Корзина'));
    await tester.pumpAndSettle();
    expect(find.byType(CartScreen), findsOneWidget);
    expect(find.text('Fjallraven Backpack'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
