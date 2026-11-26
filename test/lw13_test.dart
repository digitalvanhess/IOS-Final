import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stipa/lw13/models/diary_entry.dart';
import 'package:stipa/lw13/screens/photo_diary_screen.dart';
import 'package:stipa/lw13/services/diary_storage.dart';
import 'package:stipa/lw13/services/location_service.dart';
import 'package:stipa/lw13/services/media_service.dart';
import 'package:stipa/main.dart';
import 'package:stipa/providers/settings_provider.dart';
import 'package:stipa/screens/profile_screen.dart';
import 'package:stipa/services/notes_storage.dart';
import 'package:stipa/theme/app_theme.dart';
import 'package:stipa/utils/format.dart';

const _sizes = {
  'iPhone SE': Size(320, 568),
  'iPhone 15': Size(393, 852),
  'iPad': Size(820, 1180),
};

final _narxoz = LocationFix(
  latitude: 43.238949,
  longitude: 76.889709,
  altitude: 812.3,
  accuracy: 12.4,
  timestamp: DateTime(2026, 11, 24, 14, 30, 15),
);

class FakeMedia implements MediaService {
  MediaResult next = const MediaPicked('/no/such/photo.jpg');
  final sources = <ImageSource>[];
  int settingsOpened = 0;

  @override
  Future<MediaResult> pick(ImageSource source) async {
    sources.add(source);
    return next;
  }

  @override
  Future<bool> openAppSettings() async {
    settingsOpened++;
    return true;
  }
}

class FakeLocation implements LocationService {
  /// When set, [currentLocation] waits for it, so the spinner can be seen.
  Completer<LocationResult>? pending;
  LocationResult next = _narxoz;
  int calls = 0;
  int locationSettingsOpened = 0;
  int appSettingsOpened = 0;

  @override
  Future<LocationResult> currentLocation() {
    calls++;
    return pending?.future ?? Future.value(next);
  }

  @override
  Future<bool> openLocationSettings() async {
    locationSettingsOpened++;
    return true;
  }

  @override
  Future<bool> openAppSettings() async {
    appSettingsOpened++;
    return true;
  }
}

Future<SharedPreferences> _prefs([Map<String, Object> values = const {}]) {
  SharedPreferences.resetStatic();
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

Future<DiaryStorage> _pumpDiary(
  WidgetTester tester, {
  required FakeMedia media,
  required FakeLocation location,
  Size size = const Size(393, 852),
  ThemeData? theme,
  Map<String, Object> prefs = const {},
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final storage = DiaryStorage(await _prefs(prefs));
  await tester.pumpWidget(
    Provider.value(
      value: storage,
      child: MaterialApp(
        theme: theme ?? AppTheme.dark,
        home: PhotoDiaryScreen(media: media, location: location),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return storage;
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Diary rows are built lazily, so scroll the page until [finder] exists.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

bool _enabled(WidgetTester tester, String key) =>
    tester.widget<ButtonStyleButton>(find.byKey(ValueKey(key))).enabled;

void main() {
  group('model and storage', () {
    test('DiaryEntry survives toJson -> fromJson', () {
      final entry = DiaryEntry(
        id: '1',
        photoPath: '/docs/photo_diary/1.jpg',
        caption: 'Campus Quad',
        createdAt: DateTime(2026, 11, 24, 14, 30, 15),
        latitude: 43.238949,
        longitude: 76.889709,
        altitude: 812.3,
        accuracy: 12.4,
      );
      final back = DiaryEntry.fromJson(
        jsonDecode(jsonEncode(entry.toJson())) as Map<String, dynamic>,
      );
      expect(back.caption, 'Campus Quad');
      expect(back.photoPath, entry.photoPath);
      expect(back.createdAt, entry.createdAt);
      expect(back.latitude, 43.238949);
      expect(back.accuracy, 12.4);
      expect(back.hasLocation, isTrue);
    });

    test('entry without GPS and with int coordinates parses', () {
      final noGps = DiaryEntry.fromJson({'id': '2', 'photoPath': '/a.jpg'});
      expect(noGps.hasLocation, isFalse);
      final ints = DiaryEntry.fromJson({'latitude': 43, 'longitude': 76});
      expect(ints.latitude, 43.0);
    });

    test('storage saves, loads and ignores corrupted JSON', () async {
      final storage = DiaryStorage(await _prefs());
      expect(storage.load(), isEmpty);
      await storage.save([
        DiaryEntry(
          id: '1',
          photoPath: '/a.jpg',
          caption: 'A',
          createdAt: DateTime(2026),
        ),
      ]);
      expect(storage.load().single.caption, 'A');

      final broken = DiaryStorage(
        await _prefs({DiaryStorage.entriesKey: '{not json'}),
      );
      expect(broken.load(), isEmpty);
    });

    test('Format.stamp and Format.coordinates', () {
      expect(
        Format.stamp(DateTime(2026, 11, 24, 14, 30, 5)),
        '2026-11-24 14:30:05',
      );
      expect(
        Format.coordinates(43.238949, 76.889709),
        '43.2389° N, 76.8897° E',
      );
      expect(Format.coordinates(-33.8688, -70.6693), '33.8688° S, 70.6693° W');
    });

    test('compression settings from the task', () {
      expect(DeviceMediaService.imageQuality, 80);
      expect(DeviceMediaService.maxWidth, 1080);
    });
  });

  group('photo diary screen', () {
    testWidgets('placeholder until a photo is picked, save disabled', (
      tester,
    ) async {
      await _pumpDiary(tester, media: FakeMedia(), location: FakeLocation());

      expect(find.byIcon(Icons.photo_camera_outlined), findsWidgets);
      expect(find.text('Нажмите, чтобы добавить фото'), findsOneWidget);
      expect(_enabled(tester, 'save_entry'), isFalse);
      await _scrollTo(tester, find.text('Пока нет записей'));
      expect(find.text('Пока нет записей'), findsOneWidget);
    });

    testWidgets(
      'camera -> auto GPS with spinner -> caption -> saved to the feed',
      (tester) async {
        final media = FakeMedia();
        final location = FakeLocation()..pending = Completer<LocationResult>();
        final storage = await _pumpDiary(
          tester,
          media: media,
          location: location,
        );

        await tester.tap(find.byKey(const ValueKey('take_photo')));
        await tester.pump();
        await tester.pump();

        expect(media.sources, [ImageSource.camera]);
        expect(location.calls, 1, reason: 'GPS starts after the capture');
        expect(find.byKey(const ValueKey('gps_loading')), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        location.pending!.complete(_narxoz);
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('gps_loading')), findsNothing);
        expect(find.text('43.238949'), findsOneWidget);
        expect(find.text('76.889709'), findsOneWidget);
        expect(find.text('± 12.4 м'), findsOneWidget);
        expect(find.text('Нажмите, чтобы добавить фото'), findsNothing);
        expect(_enabled(tester, 'save_entry'), isTrue);

        await tester.enterText(
          find.byKey(const ValueKey('caption_field')),
          'Campus Quad, first snow',
        );
        await _tapKey(tester, 'save_entry');

        await _scrollTo(tester, find.text('Campus Quad, first snow'));
        expect(find.text('Campus Quad, first snow'), findsOneWidget);
        expect(find.text('43.2389° N, 76.8897° E'), findsOneWidget);
        expect(find.text('Пока нет записей'), findsNothing);
        expect(_enabled(tester, 'save_entry'), isFalse);

        final saved = storage.load().single;
        expect(saved.caption, 'Campus Quad, first snow');
        expect(saved.photoPath, '/no/such/photo.jpg');
        expect(saved.accuracy, 12.4);
      },
    );

    testWidgets('preview opens the bottom sheet, gallery is the 2nd source', (
      tester,
    ) async {
      final media = FakeMedia();
      await _pumpDiary(tester, media: media, location: FakeLocation());

      await _tapKey(tester, 'photo_preview');
      expect(find.text('Сделать фото'), findsOneWidget);
      await tester.tap(find.text('Выбрать из галереи'));
      await tester.pumpAndSettle();

      expect(media.sources, [ImageSource.gallery]);
      expect(_enabled(tester, 'save_entry'), isTrue);
    });

    testWidgets('cancelled picker changes nothing', (tester) async {
      final media = FakeMedia()..next = const MediaCancelled();
      final location = FakeLocation();
      await _pumpDiary(tester, media: media, location: location);

      await _tapKey(tester, 'pick_gallery');
      expect(location.calls, 0);
      expect(_enabled(tester, 'save_entry'), isFalse);
    });

    testWidgets('GPS off -> dialog opens the location settings', (
      tester,
    ) async {
      final location = FakeLocation()..next = const LocationServicesDisabled();
      await _pumpDiary(tester, media: FakeMedia(), location: location);

      await _tapKey(tester, 'fetch_gps');
      expect(find.text('GPS выключен'), findsOneWidget);
      await tester.tap(find.text('Включить GPS'));
      await tester.pumpAndSettle();

      expect(location.locationSettingsOpened, 1);
      expect(find.text('GPS выключен'), findsNothing);
    });

    testWidgets('location denied -> SnackBar, photo still saves', (
      tester,
    ) async {
      final location = FakeLocation()..next = const LocationPermissionDenied();
      final storage = await _pumpDiary(
        tester,
        media: FakeMedia(),
        location: location,
      );

      await _tapKey(tester, 'take_photo');
      expect(
        find.textContaining('Доступ к геолокации запрещён'),
        findsOneWidget,
      );

      await _tapKey(tester, 'save_entry');
      await _scrollTo(tester, find.text('Без подписи'));
      expect(find.text('Без подписи'), findsOneWidget);
      expect(find.text('Без координат'), findsOneWidget);
      expect(storage.load().single.hasLocation, isFalse);
    });

    testWidgets('"Don\'t ask again" -> dialog opens the app settings', (
      tester,
    ) async {
      final location = FakeLocation()
        ..next = const LocationPermissionDeniedForever();
      await _pumpDiary(tester, media: FakeMedia(), location: location);

      await _tapKey(tester, 'fetch_gps');
      expect(find.text('Нет доступа к геолокации'), findsOneWidget);
      await tester.tap(find.text('Открыть настройки'));
      await tester.pumpAndSettle();
      expect(location.appSettingsOpened, 1);
    });

    testWidgets('camera permanently denied -> settings dialog, no crash', (
      tester,
    ) async {
      final media = FakeMedia()
        ..next = const MediaPermissionDenied(permanently: true);
      final location = FakeLocation();
      await _pumpDiary(tester, media: media, location: location);

      await _tapKey(tester, 'take_photo');
      expect(find.text('Нет доступа к камере'), findsOneWidget);
      await tester.tap(find.text('Не сейчас'));
      await tester.pumpAndSettle();

      expect(media.settingsOpened, 0);
      expect(location.calls, 0);
      expect(_enabled(tester, 'save_entry'), isFalse);
    });

    testWidgets('camera denied once -> SnackBar', (tester) async {
      final media = FakeMedia()
        ..next = const MediaPermissionDenied(permanently: false);
      await _pumpDiary(tester, media: media, location: FakeLocation());

      await _tapKey(tester, 'take_photo');
      expect(
        find.text('Без доступа к камере снять фото нельзя'),
        findsOneWidget,
      );
    });

    testWidgets('saved entries load on open; swipe deletes, UNDO restores', (
      tester,
    ) async {
      final entry = DiaryEntry(
        id: '1',
        photoPath: '/a.jpg',
        caption: 'Library',
        createdAt: DateTime(2026, 11, 20, 9, 5),
        latitude: 43.2,
        longitude: 76.9,
      );
      final storage = await _pumpDiary(
        tester,
        media: FakeMedia(),
        location: FakeLocation(),
        prefs: {
          DiaryStorage.entriesKey: jsonEncode([entry.toJson()]),
        },
      );

      final tile = find.text('Library');
      await _scrollTo(tester, tile);
      expect(tile, findsOneWidget);
      expect(find.text('2026-11-20 09:05:00'), findsOneWidget);
      await tester.drag(tile, const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Library'), findsNothing);
      expect(storage.load(), isEmpty);

      await tester.tap(find.text('Отменить'));
      await tester.pumpAndSettle();
      expect(find.text('Library'), findsOneWidget);
      expect(storage.load().single.id, '1');
    });

    for (final MapEntry(key: name, value: size) in _sizes.entries) {
      for (final (label, theme) in [
        ('dark', AppTheme.dark),
        ('light', AppTheme.light),
      ]) {
        testWidgets('no overflow on $name ($label)', (tester) async {
          final entries = List.generate(
            3,
            (i) => DiaryEntry(
              id: '$i',
              photoPath: '/p$i.jpg',
              caption: 'A very long caption for the diary entry number $i',
              createdAt: DateTime(2026, 11, 24),
              latitude: -43.238949,
              longitude: -176.889709,
            ).toJson(),
          );
          await _pumpDiary(
            tester,
            media: FakeMedia(),
            location: FakeLocation(),
            size: size,
            theme: theme,
            prefs: {DiaryStorage.entriesKey: jsonEncode(entries)},
          );
          await _tapKey(tester, 'take_photo');
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -2000),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  testWidgets('Профиль -> Фотодневник opens the diary', (tester) async {
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final prefs = await _prefs();
    await tester.pumpWidget(
      StipaApp(
        settings: SettingsProvider.fromPrefs(prefs),
        notesStorage: NotesStorage(prefs),
        diaryStorage: DiaryStorage(prefs),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Профиль').last);
    await tester.pumpAndSettle();

    final tile = find.text('Фотодневник');
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

    expect(find.byType(PhotoDiaryScreen), findsOneWidget);
    expect(find.text('📸 Narxoz Photo Journal'), findsOneWidget);
  });
}
