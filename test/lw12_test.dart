import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stipa/lw12/bloc/auth/auth_cubit.dart';
import 'package:stipa/lw12/bloc/cart/cart_bloc.dart';
import 'package:stipa/lw12/data/shop_catalog.dart';
import 'package:stipa/lw12/screens/login_screen.dart';
import 'package:stipa/lw12/screens/shop_cart_screen.dart';
import 'package:stipa/lw12/screens/shop_catalog_screen.dart';
import 'package:stipa/main.dart';
import 'package:stipa/providers/settings_provider.dart';
import 'package:stipa/screens/profile_screen.dart';
import 'package:stipa/services/notes_storage.dart';
import 'package:stipa/utils/format.dart';

const _sizes = {
  'iPhone SE': Size(320, 568),
  'iPhone 15': Size(393, 852),
  'iPad': Size(820, 1180),
};

const _delay = Duration(milliseconds: 500);

final _headphones = ShopCatalog.products[0]; // 14 990 ₸
final _mug = ShopCatalog.products[2]; // 5 900 ₸

Future<void> _launch(
  WidgetTester tester, {
  Size size = const Size(393, 852),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.resetStatic();
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    StipaApp(
      settings: SettingsProvider.fromPrefs(prefs),
      notesStorage: NotesStorage(prefs),
      authDelay: _delay,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openShop(WidgetTester tester) async {
  await tester.tap(find.text('Профиль').last);
  await tester.pumpAndSettle();
  final tile = find.text('Магазин с входом');
  await tester.scrollUntilVisible(
    tile,
    200,
    scrollable: find
        .descendant(
          of: find.byType(ProfileScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

Future<void> _login(
  WidgetTester tester, {
  String email = AuthCubit.demoEmail,
  String password = AuthCubit.demoPassword,
}) async {
  await tester.enterText(find.byKey(const ValueKey('login_email')), email);
  await tester.enterText(
    find.byKey(const ValueKey('login_password')),
    password,
  );
  await tester.tap(find.byKey(const ValueKey('login_button')));
  await tester.pump();
}

String? _badgeText(WidgetTester tester) {
  final badge = tester.widget<Badge>(
    find.byKey(const ValueKey('cart_badge')).last,
  );
  if (badge.isLabelVisible != true) return null;
  return (badge.label! as Text).data;
}

void main() {
  group('AuthCubit', () {
    test('starts in AuthInitial', () {
      expect(AuthCubit().state, const AuthInitial());
    });

    test('valid credentials: Loading -> Success', () async {
      final cubit = AuthCubit(delay: Duration.zero);
      final states = expectLater(
        cubit.stream,
        emitsInOrder([
          const AuthLoading(),
          const AuthSuccess(
            username: AuthCubit.demoUsername,
            email: AuthCubit.demoEmail,
          ),
        ]),
      );
      // Spaces and capitals in the email are forgiven.
      await cubit.login('  Student@Narxoz.kz ', '123456');
      await states;
    });

    for (final c in [
      ('', '', 'Введите email и пароль'),
      ('student', '123456', 'Некорректный email'),
      ('student@narxoz.kz', '123', 'Пароль должен быть не короче 6 символов'),
      ('student@narxoz.kz', '654321', 'Неверный email или пароль'),
      ('other@narxoz.kz', '123456', 'Неверный email или пароль'),
    ]) {
      test('"${c.$1}" / "${c.$2}" -> AuthError(${c.$3})', () async {
        final cubit = AuthCubit(delay: Duration.zero);
        final states = expectLater(
          cubit.stream,
          emitsInOrder([const AuthLoading(), AuthError(c.$3)]),
        );
        await cubit.login(c.$1, c.$2);
        await states;
      });
    }

    test('Equatable: equal states, different instances', () {
      expect(const AuthError('a'), AuthError('a'.toString()));
      expect(const AuthError('a'), isNot(const AuthError('b')));
      expect(
        const AuthSuccess(username: 'u', email: 'e'),
        isNot(const AuthSuccess(username: 'u', email: 'x')),
      );
    });

    test('second tap during loading is ignored', () async {
      final cubit = AuthCubit(delay: _delay);
      final emitted = <AuthState>[];
      cubit.stream.listen(emitted.add);
      final first = cubit.login(AuthCubit.demoEmail, AuthCubit.demoPassword);
      await cubit.login(AuthCubit.demoEmail, AuthCubit.demoPassword);
      await first;
      await Future<void>.delayed(Duration.zero);
      expect(emitted, [
        const AuthLoading(),
        const AuthSuccess(
          username: AuthCubit.demoUsername,
          email: AuthCubit.demoEmail,
        ),
      ]);
    });

    test('logout -> AuthInitial', () async {
      final cubit = AuthCubit(delay: Duration.zero);
      await cubit.login(AuthCubit.demoEmail, AuthCubit.demoPassword);
      cubit.logout();
      expect(cubit.state, const AuthInitial());
    });
  });

  group('CartBloc', () {
    Future<CartState> run(List<CartEvent> events) async {
      final bloc = CartBloc();
      for (final e in events) {
        bloc.add(e);
      }
      await Future<void>.delayed(Duration.zero);
      final state = bloc.state;
      await bloc.close();
      return state;
    }

    test('starts empty', () {
      expect(CartBloc().state, const CartState());
    });

    test('AddProductEvent adds lines and raises quantity', () async {
      final state = await run([
        AddProductEvent(_headphones),
        AddProductEvent(_mug),
        AddProductEvent(_headphones),
      ]);
      expect(state.items.length, 2);
      expect(state.quantityOf(_headphones.id), 2);
      expect(state.count, 3);
      expect(state.totalPrice, 14990 * 2 + 5900);
    });

    test('RemoveProductEvent removes the whole line', () async {
      final state = await run([
        AddProductEvent(_headphones),
        AddProductEvent(_headphones),
        AddProductEvent(_mug),
        RemoveProductEvent(_headphones.id),
      ]);
      expect(state.items.map((i) => i.product), [_mug]);
      expect(state.count, 1);
      expect(state.totalPrice, 5900);
    });

    test('ClearCartEvent empties the cart', () async {
      final state = await run([
        AddProductEvent(_headphones),
        AddProductEvent(_mug),
        const ClearCartEvent(),
      ]);
      expect(state, const CartState());
    });

    test('state is immutable', () async {
      final state = await run([AddProductEvent(_mug)]);
      expect(
        () => state.items.add(CartItem(product: _headphones)),
        throwsUnsupportedError,
      );
    });
  });

  testWidgets('wrong password: spinner, then red floating SnackBar', (
    tester,
  ) async {
    await _launch(tester);
    await _openShop(tester);
    expect(find.byType(LoginScreen), findsOneWidget);

    await _login(tester, password: '000000');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byKey(const ValueKey('login_button')), findsNothing);

    await tester.pump(_delay);
    await tester.pump();
    final snack = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snack.behavior, SnackBarBehavior.floating);
    expect(snack.backgroundColor, const Color(0xFFC4532F));
    expect(find.text('Неверный email или пароль'), findsOneWidget);
    expect(find.byKey(const ValueKey('login_button')), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);

    // Same error twice still shows the SnackBar (Loading sits in between).
    await tester.pumpAndSettle(const Duration(seconds: 5));
    await _login(tester, password: '000000');
    await tester.pump(_delay);
    await tester.pump();
    expect(find.text('Неверный email или пароль'), findsOneWidget);
  });

  for (final entry in _sizes.entries) {
    testWidgets('login -> catalog -> cart flow on ${entry.key}', (
      tester,
    ) async {
      await _launch(tester, size: entry.value);
      await _openShop(tester);
      await _login(tester);
      await tester.pump(_delay);
      await tester.pumpAndSettle();

      expect(find.byType(ShopCatalogScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.textContaining(AuthCubit.demoUsername), findsOneWidget);
      expect(_badgeText(tester), isNull);

      await tester.tap(find.byKey(ValueKey('add_${_headphones.id}')));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey('add_${_headphones.id}')));
      await tester.pump();
      expect(find.text('в корзине: 2'), findsOneWidget);
      expect(_badgeText(tester), '2');
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('add_${_mug.id}')),
        100,
      );
      await tester.ensureVisible(find.byKey(ValueKey('add_${_mug.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('add_${_mug.id}')));
      await tester.pumpAndSettle();
      expect(_badgeText(tester), '3');

      await tester.tap(find.byTooltip('Корзина'));
      await tester.pumpAndSettle();
      expect(find.byType(ShopCartScreen), findsOneWidget);
      expect(_badgeText(tester), '3');
      expect(find.text(Format.money(35880)), findsOneWidget);
      expect(find.text('2 × ${Format.money(14990)}'), findsOneWidget);

      await tester.tap(find.byKey(ValueKey('remove_${_headphones.id}')));
      await tester.pumpAndSettle();
      expect(find.text(Format.money(5900)), findsWidgets);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('cart_total'))).data,
        Format.money(5900),
      );
      expect(_badgeText(tester), '1');

      await tester.tap(find.byKey(const ValueKey('clear_cart')));
      await tester.pumpAndSettle();
      expect(find.text('Корзина пуста'), findsOneWidget);
      expect(_badgeText(tester), isNull);

      // Back on the catalog route the badge is in sync.
      await tester.tap(find.text('В магазин'));
      await tester.pumpAndSettle();
      expect(find.byType(ShopCatalogScreen), findsOneWidget);
      expect(_badgeText(tester), isNull);
      expect(find.textContaining('в корзине'), findsNothing);

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('back from catalog goes to Профиль, re-entry skips login', (
    tester,
  ) async {
    await _launch(tester);
    await _openShop(tester);
    await _login(tester);
    await tester.pump(_delay);
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);

    await _openShop(tester);
    expect(find.byType(ShopCatalogScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Выйти'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
