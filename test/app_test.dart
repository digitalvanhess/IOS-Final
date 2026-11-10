import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stipa/main.dart';
import 'package:stipa/screens/cart_screen.dart';
import 'package:stipa/screens/catalog_screen.dart';
import 'package:stipa/screens/add_expense_screen.dart';
import 'package:stipa/screens/expense_detail_screen.dart';
import 'package:stipa/screens/history_screen.dart';
import 'package:stipa/utils/format.dart';
import 'package:stipa/widgets/expense_list_row.dart';

/// Phone sizes we check for layout overflows (logical pixels).
const _sizes = {
  'iPhone SE': Size(320, 568),
  'iPhone 15': Size(393, 852),
  'iPad': Size(820, 1180),
};

Future<void> _pumpApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const StipaApp());
  await tester.pumpAndSettle();
}

/// Scrolls until [finder] is built, then a bit further so it is not
/// hidden behind the bottom navigation bar.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200);
  await tester.drag(find.byType(CustomScrollView).first, const Offset(0, -200));
  await tester.pumpAndSettle();
}

void main() {
  for (final entry in _sizes.entries) {
    testWidgets('all screens render without overflow on ${entry.key}', (
      tester,
    ) async {
      await _pumpApp(tester, entry.value);
      expect(find.text('Сегодня можно потратить'), findsOneWidget);

      for (final tab in ['Обзор', 'Избранное', 'Профиль', 'Сегодня']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
      }

      await _scrollTo(tester, find.text('Обед в столовой'));
      await tester.tap(find.text('Обед в столовой').first);
      await tester.pumpAndSettle();
      expect(find.byType(ExpenseDetailScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Назад'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Новый расход'));
      await tester.pumpAndSettle();
      expect(find.byType(AddExpenseScreen), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('detail screen gets the tapped expense and pops back', (
    tester,
  ) async {
    await _pumpApp(tester, _sizes['iPhone 15']!);

    await _scrollTo(tester, find.text('Кофе с собой'));
    await tester.tap(find.text('Кофе с собой').first);
    await tester.pumpAndSettle();
    expect(find.text('Coffee Boom'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('К тратам'), 200);
    await tester.tap(find.text('К тратам'));
    await tester.pumpAndSettle();
    expect(find.byType(ExpenseDetailScreen), findsNothing);
    expect(find.text('Сегодня можно потратить'), findsOneWidget);
  });

  testWidgets('adding an expense updates the list', (tester) async {
    await _pumpApp(tester, _sizes['iPhone 15']!);

    await tester.tap(find.byTooltip('Новый расход'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Транспорт'));
    for (final key in ['2', '0', '0']) {
      await tester.tap(find.text(key).last);
    }
    await tester.pump();
    await tester.tap(find.text('Сохранить расход'));
    await tester.pumpAndSettle();

    expect(find.byType(AddExpenseScreen), findsNothing);
    expect(find.textContaining('Расход сохранён'), findsOneWidget);
  });

  testWidgets('favorite toggle moves an expense into Избранное', (
    tester,
  ) async {
    await _pumpApp(tester, _sizes['iPhone 15']!);

    await _scrollTo(tester, find.byTooltip('В избранное').first);
    await tester.tap(find.byTooltip('В избранное').first);
    await tester.pump();
    await tester.tap(find.text('Избранное').last);
    await tester.pumpAndSettle();

    expect(find.text('Обед в столовой'), findsOneWidget);
  });

  for (final entry in _sizes.entries) {
    testWidgets('Все траты: list and grid render without overflow on '
        '${entry.key}', (tester) async {
      await _pumpApp(tester, entry.value);
      await tester.tap(find.byTooltip('Все траты'));
      await tester.pumpAndSettle();
      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);

      await tester.tap(find.byTooltip('Сеткой'));
      await tester.pumpAndSettle();
      expect(find.byType(GridView), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('swipe deletes an expense and UNDO restores it', (tester) async {
    await _pumpApp(tester, _sizes['iPhone 15']!);
    await tester.tap(find.byTooltip('Все траты'));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Обед в столовой'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Обед в столовой'), findsNothing);
    expect(find.text('ОТМЕНИТЬ'), findsOneWidget);

    await tester.tap(find.text('ОТМЕНИТЬ'));
    await tester.pumpAndSettle();
    expect(find.text('Обед в столовой'), findsOneWidget);
  });

  testWidgets('pull-to-refresh adds a new expense at the top', (tester) async {
    await _pumpApp(tester, _sizes['iPhone 15']!);
    await tester.tap(find.byTooltip('Все траты'));
    await tester.pumpAndSettle();
    final before = find.byType(ExpenseListRow).evaluate().length;

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.byType(ExpenseListRow).evaluate().length, before + 1);
    expect(find.text('Сегодня').first, findsOneWidget);
  });

  testWidgets('empty catalog shows Reset Catalog', (tester) async {
    await _pumpApp(tester, _sizes['iPad']!);
    await tester.tap(find.byTooltip('Все траты'));
    await tester.pumpAndSettle();

    // Count rows, not Dismissibles: the SnackBar is a Dismissible too.
    for (var i = 0; i < 10; i++) {
      final rows = find.byType(ExpenseListRow);
      if (rows.evaluate().isEmpty) break;
      await tester.drag(rows.first, const Offset(-900, 0));
      await tester.pumpAndSettle();
    }
    expect(find.text('Catalog is Empty'), findsOneWidget);

    await tester.tap(find.text('Reset Catalog'));
    await tester.pumpAndSettle();
    expect(find.text('Обед в столовой'), findsOneWidget);
  });

  Future<void> openCatalog(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Покупки'));
    await tester.pumpAndSettle();
    expect(find.byType(CatalogScreen), findsOneWidget);
  }

  Future<void> openCart(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Корзина'));
    await tester.pumpAndSettle();
    expect(find.byType(CartScreen), findsOneWidget);
  }

  /// Text of the count badge, or null when it is hidden.
  String? badge(WidgetTester tester) {
    final texts = find.descendant(
      of: find.byTooltip('Корзина'),
      matching: find.byType(Text),
    );
    if (texts.evaluate().isEmpty) return null;
    return tester.widget<Text>(texts.first).data;
  }

  List<bool> switches(WidgetTester tester) => tester
      .widgetList<Switch>(find.byType(Switch))
      .map((s) => s.value)
      .toList();

  for (final entry in _sizes.entries) {
    testWidgets('Покупки and Корзина render without overflow on '
        '${entry.key}', (tester) async {
      await _pumpApp(tester, entry.value);
      await openCatalog(tester);
      await openCart(tester);
      expect(find.text('Корзина пуста'), findsOneWidget);
      await tester.tap(find.text('К покупкам'));
      await tester.pumpAndSettle();

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byType(Switch).at(i));
        await tester.pumpAndSettle();
      }
      await openCart(tester);
      expect(find.text('Итого · 3 покупки'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cart is shared: badge, total, delete + undo, clear all', (
    tester,
  ) async {
    await _pumpApp(tester, _sizes['iPhone 15']!);
    await openCatalog(tester);
    expect(badge(tester), isNull);

    // Проездной 4 000 + Продукты 15 000.
    await tester.tap(find.byType(Switch).at(0));
    await tester.tap(find.byType(Switch).at(2));
    await tester.pumpAndSettle();
    expect(badge(tester), '2');

    await openCart(tester);
    expect(find.text(Format.money(19000)), findsOneWidget);

    // Delete on the cart screen shows up in the catalog right away.
    await tester.tap(find.byTooltip('Убрать').first);
    await tester.pumpAndSettle();
    expect(find.text('Проездной на месяц'), findsNothing);
    expect(find.text(Format.money(15000)), findsNWidgets(2)); // row + total
    expect(find.text('Отменить'), findsOneWidget);

    await tester.tap(find.text('Отменить'));
    await tester.pumpAndSettle();
    expect(find.text('Проездной на месяц'), findsOneWidget);
    expect(find.text(Format.money(19000)), findsOneWidget);

    await tester.tap(find.byTooltip('Убрать').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(switches(tester), [false, false, true, false, false, false]);
    expect(badge(tester), '1');

    // «Очистить всё»: cancel keeps items, confirm empties the cart.
    await openCart(tester);
    await tester.tap(find.text('Очистить всё'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(find.text('Продукты на неделю'), findsOneWidget);

    await tester.tap(find.text('Очистить всё'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Очистить'));
    await tester.pumpAndSettle();
    expect(find.text('Корзина пуста'), findsOneWidget);

    await tester.tap(find.text('К покупкам'));
    await tester.pumpAndSettle();
    expect(switches(tester), everyElement(isFalse));
    expect(badge(tester), isNull);
  });
}
