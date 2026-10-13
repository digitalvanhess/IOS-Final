import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stipa/main.dart';
import 'package:stipa/screens/add_expense_screen.dart';
import 'package:stipa/screens/expense_detail_screen.dart';

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
}
