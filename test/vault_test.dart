import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stipa/main.dart';
import 'package:stipa/models/note_item.dart';
import 'package:stipa/providers/settings_provider.dart';
import 'package:stipa/screens/profile_screen.dart';
import 'package:stipa/screens/vault_screen.dart';
import 'package:stipa/services/notes_storage.dart';

const _sizes = {
  'iPhone SE': Size(320, 568),
  'iPhone 15': Size(393, 852),
  'iPad': Size(820, 1180),
};

/// Starts the app the same way main() does: prefs first, then runApp.
Future<SharedPreferences> _launch(
  WidgetTester tester, {
  Map<String, Object> disk = const {},
  Size size = const Size(393, 852),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.resetStatic();
  SharedPreferences.setMockInitialValues(disk);
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    StipaApp(
      settings: SettingsProvider.fromPrefs(prefs),
      notesStorage: NotesStorage(prefs),
    ),
  );
  await tester.pumpAndSettle();
  return prefs;
}

/// "Force quit": copy everything that is on disk, throw the widget tree and
/// the prefs singleton away.
Future<Map<String, Object>> _kill(
  WidgetTester tester,
  SharedPreferences prefs,
) async {
  final disk = {for (final k in prefs.getKeys()) k: prefs.get(k)!};
  await tester.pumpWidget(const SizedBox());
  return disk;
}

/// Profile is a lazy ListView: on small phones the tile is not built yet.
Future<void> _scrollToVaultTile(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Заметки и настройки'),
    200,
    scrollable: find
        .descendant(
          of: find.byType(ProfileScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.ensureVisible(find.text('Заметки и настройки'));
}

Future<void> _openVault(WidgetTester tester) async {
  await tester.tap(find.text('Профиль').last);
  await tester.pumpAndSettle();
  await _scrollToVaultTile(tester);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Заметки и настройки'));
  await tester.pumpAndSettle();
  expect(find.byType(VaultScreen), findsOneWidget);
}

Brightness _vaultBrightness(WidgetTester tester) {
  final context = tester.element(find.text('Мои заметки', skipOffstage: false));
  return Theme.of(context).brightness;
}

Future<void> _addNote(WidgetTester tester, String title) async {
  await tester.enterText(find.byKey(const ValueKey('note_field')), title);
  await tester.tap(find.byTooltip('Добавить заметку'));
  await tester.pumpAndSettle();
}

List<dynamic> _notesOnDisk(SharedPreferences prefs) =>
    jsonDecode(prefs.getString(NotesStorage.notesKey)!) as List<dynamic>;

void main() {
  group('NoteItem JSON', () {
    test('toJson -> jsonEncode -> jsonDecode -> fromJson keeps all fields', () {
      const note = NoteItem(
        id: '1',
        title: 'Купить проездной',
        dateText: '18 ноября, 12:30',
        isCompleted: true,
      );
      final raw = jsonEncode([note.toJson()]);
      final back = NoteItem.fromJson(
        (jsonDecode(raw) as List).first as Map<String, dynamic>,
      );
      expect(back.id, '1');
      expect(back.title, 'Купить проездной');
      expect(back.dateText, '18 ноября, 12:30');
      expect(back.isCompleted, isTrue);
    });

    test('fromJson falls back on missing fields', () {
      final note = NoteItem.fromJson({'title': 'Без даты'});
      expect(note.id, '');
      expect(note.dateText, '');
      expect(note.isCompleted, isFalse);
    });

    test('corrupted JSON on disk gives an empty list, not a crash', () async {
      SharedPreferences.resetStatic();
      SharedPreferences.setMockInitialValues({NotesStorage.notesKey: '{oops'});
      final prefs = await SharedPreferences.getInstance();
      expect(NotesStorage(prefs).load(), isEmpty);
    });
  });

  for (final entry in _sizes.entries) {
    testWidgets('vault renders in both themes on ${entry.key}', (tester) async {
      await _launch(tester, size: entry.value);
      await _openVault(tester);
      expect(find.text('Привет, Guest User'), findsOneWidget);
      expect(find.text('Заметок пока нет'), findsOneWidget);
      expect(_vaultBrightness(tester), Brightness.light);

      await _addNote(tester, 'Очень длинная заметка про стипендию и проездной');
      await tester.tap(find.byKey(const ValueKey('dark_mode_switch')));
      await tester.pumpAndSettle();
      expect(_vaultBrightness(tester), Brightness.dark);

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cold restart restores theme, name and notes', (tester) async {
    var prefs = await _launch(tester);
    await _openVault(tester);

    await _addNote(tester, 'Первая');
    await _addNote(tester, 'Вторая');
    // Prepend: the newest note is on top.
    expect(
      tester.getTopLeft(find.text('Вторая')).dy,
      lessThan(tester.getTopLeft(find.text('Первая')).dy),
    );

    await tester.tap(find.text('Первая'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('dark_mode_switch')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('name_field')), 'Иван');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Привет, Иван'), findsOneWidget);

    expect(prefs.getBool(SettingsProvider.darkModeKey), isTrue);
    expect(prefs.getString(SettingsProvider.displayNameKey), 'Иван');
    expect(_notesOnDisk(prefs).map((n) => n['title']), ['Вторая', 'Первая']);

    // Force-quit and reopen.
    final disk = await _kill(tester, prefs);
    prefs = await _launch(tester, disk: disk);

    // Profile header already shows the saved name.
    await tester.tap(find.text('Профиль').last);
    await tester.pumpAndSettle();
    expect(find.text('Иван'), findsOneWidget);

    await _openVault(tester);
    expect(_vaultBrightness(tester), Brightness.dark);
    expect(find.text('Привет, Иван'), findsOneWidget);
    expect(find.text('Вторая'), findsOneWidget);
    expect(find.text('1 из 2'), findsOneWidget);
    final first = tester.widget<Checkbox>(
      find.descendant(
        of: find.ancestor(
          of: find.text('Первая'),
          matching: find.byType(ListTile),
        ),
        matching: find.byType(Checkbox),
      ),
    );
    expect(first.value, isTrue);
  });

  testWidgets('dark theme is applied on the very first frame', (tester) async {
    await _launch(tester, disk: {SettingsProvider.darkModeKey: true});
    await tester.tap(find.text('Профиль').last);
    await tester.pumpAndSettle();
    await _scrollToVaultTile(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Заметки и настройки'));
    await tester.pump(); // first frame of the new route, no settle
    expect(_vaultBrightness(tester), Brightness.dark);
  });

  testWidgets('dark mode switch themes the whole app', (tester) async {
    Brightness tabBrightness() =>
        Theme.of(tester.element(find.byType(BottomNavigationBar))).brightness;

    // Saved dark theme: the very first frame of the main screen is dark.
    final prefs = await _launch(
      tester,
      disk: {SettingsProvider.darkModeKey: true},
    );
    expect(tabBrightness(), Brightness.dark);

    await _openVault(tester);
    await tester.tap(find.byKey(const ValueKey('dark_mode_switch')));
    await tester.pumpAndSettle();
    expect(prefs.getBool(SettingsProvider.darkModeKey), isFalse);

    // Back on the tabs: they are light now too.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(tabBrightness(), Brightness.light);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delete syncs disk, undo restores it', (tester) async {
    final prefs = await _launch(
      tester,
      disk: {
        NotesStorage.notesKey: jsonEncode([
          const NoteItem(id: 'a', title: 'A', dateText: 'x').toJson(),
          const NoteItem(id: 'b', title: 'B', dateText: 'y').toJson(),
        ]),
      },
    );
    await _openVault(tester);

    await tester.tap(find.byTooltip('Удалить заметку').first);
    await tester.pumpAndSettle();
    expect(find.text('A'), findsNothing);
    expect(_notesOnDisk(prefs).map((n) => n['id']), ['b']);

    await tester.tap(find.text('Отменить'));
    await tester.pumpAndSettle();
    expect(_notesOnDisk(prefs).map((n) => n['id']), ['a', 'b']);
  });

  testWidgets('empty name falls back to Guest User', (tester) async {
    final prefs = await _launch(
      tester,
      disk: {SettingsProvider.displayNameKey: 'Иван'},
    );
    await _openVault(tester);
    expect(find.text('Привет, Иван'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('name_field')), '   ');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Привет, Guest User'), findsOneWidget);
    expect(prefs.getString(SettingsProvider.displayNameKey), isNull);
  });
}
