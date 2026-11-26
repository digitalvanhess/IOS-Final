# Stipa · student stipend tracker

> Flutter capstone project for the iOS Development course.
> Milestone 1: MVP UI layout + Lab #7: multi-screen navigation.

**Stipa** helps a student make the stipend last until the next payment.
Instead of a long list of transactions, it answers one question:
**"How much can I spend today?"**

The app takes the money left for the period, divides it by the days until the
next stipend and shows today's limit as a ring. Every expense is entered in a
couple of taps, and the limit updates instantly.

## The problem and the user

| | |
|---|---|
| **User** | A university student living on a monthly stipend (in ₸) |
| **Problem** | The money runs out a week before the next payment, because it is hard to feel how much a single coffee or taxi "costs" against the whole month |
| **Solution** | A daily limit that recalculates itself, a warning before overspending, and a quick overview of where the money goes |

## Features (Milestone 1)

- **Сегодня (Feed):** budget ring "Сегодня можно потратить", days until the stipend, money left for the period, recent expenses list
- **Expense detail:** photo banner with the amount overlaid (Stack), tags (date, time, place, hashtags), share of the daily limit, comment
- **Новый расход:** custom keypad, category chips, live hint of what is left for today, red **"Всё равно сохранить"** button when the limit is exceeded
- **Обзор:** spending by category for a week or a month (toggle)
- **Избранное:** starred expenses, with an empty state
- **Профиль:** stats and settings switches
- Undo for added and deleted expenses (SnackBar action)
- Responsive layout: two columns on wide screens (iPad / landscape)
- Dark theme with a lime accent, following the Figma mockup

## Course requirements checklist

### Milestone 1 (Weeks 5–7)

| Requirement | Where |
|---|---|
| Feed screen with `Column`, `Row`, `Card` | [`today_screen.dart`](lib/screens/today_screen.dart), [`expense_tile.dart`](lib/widgets/expense_tile.dart) |
| Detail screen with a `Stack` overlay banner | `_Banner` in [`expense_detail_screen.dart`](lib/screens/expense_detail_screen.dart) |
| Tags | `Wrap` of [`TagChip`](lib/widgets/tag_chip.dart) on the detail screen |
| Responsive layout | `LayoutBuilder` in the Today and Detail screens, `Expanded` in rows, `FittedBox` for large amounts |
| `StatefulWidget` + `setState()` | favorite star ([`favorite_button.dart`](lib/widgets/favorite_button.dart)), keypad and categories ([`add_expense_screen.dart`](lib/screens/add_expense_screen.dart)), week/month toggle ([`overview_screen.dart`](lib/screens/overview_screen.dart)), switches in Profile, "Все / Свернуть" in the feed |
| Clean folder structure | see below |
| Zero RenderFlex overflows | checked by widget tests on iPhone SE, iPhone 15 and iPad sizes ([`test/app_test.dart`](test/app_test.dart)) |

### Lab #7: Navigation & Tabs

| Requirement | Where |
|---|---|
| Root screen with `BottomNavigationBar` (Feed, Favorites, Profile) | [`root_screen.dart`](lib/screens/root_screen.dart): Сегодня, Обзор, ➕, Избранное, Профиль |
| Feed with items: image, title, price, date | `ExpenseTile`: photo, title, "Сегодня · Еда", amount |
| `Navigator.push` with the full object | `_openDetail(Expense)` passes the whole `Expense` (title, description, image, amount, category…) to `ExpenseDetailScreen` |
| `Navigator.pop` from the AppBar **and** an in-body button | back arrow in the AppBar and the **"К тратам"** button |
| State is kept after going back | tabs live in an `IndexedStack`; favorites and expenses live in `RootScreen` |
| Bonus: data back from a screen | `AddExpenseScreen` pops with the new `Expense`, detail pops with `true` on delete |

### Lab #8: Dynamic Lists, Grids & Touch Gestures

Screen **«Все траты»** ([`history_screen.dart`](lib/screens/history_screen.dart)), opened by the receipt icon in the top bar of «Сегодня».

| Requirement | Where |
|---|---|
| `ListView.separated` with thin dividers | `_buildList()`: `Divider(height: 1, thickness: 0.5)` between [`ExpenseListRow`](lib/widgets/expense_list_row.dart)s (avatar, title, category tag, star, price) |
| 2-column `GridView.builder`, `childAspectRatio: 0.72` | `_buildGrid()` with [`ExpenseGridCard`](lib/widgets/expense_grid_card.dart): photo in `Expanded`, fixed text lines, so no overflow |
| List / Grid toggle | AppBar `IconButton` («Сеткой» / «Списком») |
| Pull-to-refresh | `RefreshIndicator` → `_refresh()`: `await Future.delayed(1500 ms)`, then `_items.insert(0, MockData.randomExpense())` in `setState` |
| Swipe-to-delete | `Dismissible(key: ValueKey(expense.id), direction: endToStart)` with a red background and `Icons.delete` |
| UNDO | floating `SnackBar` with «ОТМЕНИТЬ», `_items.insert(index, expense)` puts it back at its original index |
| Empty state | «Catalog is Empty» with an icon and a **Reset Catalog** button that restores the seed data |
| Tests | list/grid without overflow on 3 sizes, swipe + undo, refresh, empty state ([`test/app_test.dart`](test/app_test.dart)) |

### Lab #9: Multi-Screen Global Cart with Live Badge (provider)

Screen **«Покупки»** ([`catalog_screen.dart`](lib/screens/catalog_screen.dart)), opened by the shopping bag icon in the top bar of «Сегодня», and **«Корзина»** ([`cart_screen.dart`](lib/screens/cart_screen.dart)).

| Requirement | Where |
|---|---|
| `provider` package | `pubspec.yaml` — the only new dependency |
| `CartProvider extends ChangeNotifier` | [`cart_provider.dart`](lib/providers/cart_provider.dart): `items`, `add` / `remove` / `toggle` / `clear`, `isInCart`, `count`, `totalPrice` |
| `ChangeNotifierProvider` above `MaterialApp` | [`main.dart`](lib/main.dart), so every pushed route reads the same cart |
| Catalog of 6 items with a «В корзину» switch | `MockData.plannedPurchases` (planned student purchases in ₸), each row uses `context.select((c) => c.isInCart(item))` |
| Live badge in the AppBar | [`CartBadgeButton`](lib/widgets/cart_badge_button.dart): `context.select((c) => c.count)` + `ScaleTransition` pop when the count changes |
| Cart: list, delete with «Отменить», total in ₸ | `context.watch<CartProvider>()`; UNDO puts the item back at its old index |
| «Очистить всё» with confirmation | `AlertDialog` (Отмена / Очистить) |
| Empty state | «Корзина пуста» with a «К покупкам» button |
| Delete in the cart updates the catalog | no local state on the catalog: switches and badge come from the provider |
| Tests | both screens without overflow on 3 sizes; badge, total, delete + undo, clear all and sync back to the catalog ([`test/app_test.dart`](test/app_test.dart)) |

### Lab #10: Cloud Product Explorer & Detail Carousel (REST API)

Screen **«Онлайн-магазин»** ([`products_screen.dart`](lib/screens/products_screen.dart)), opened by the storefront icon in the AppBar of «Покупки», and **«Товар»** ([`product_detail_screen.dart`](lib/screens/product_detail_screen.dart)). Data: `GET https://fakestoreapi.com/products`.

| Requirement | Where |
|---|---|
| `http: ^1.2.0` | `pubspec.yaml`; `INTERNET` permission in the Android manifest for release builds |
| Model `Product` (`id`, `title`, `price`, `description`, `category`, `imageUrl`, `rating`, `reviewCount`) | [`product.dart`](lib/models/product.dart) |
| `Product.fromJson` with null-safe fallbacks and numeric safety | every number read as `num` then `.toDouble()` / `.toInt()` (`"price": 22` does not crash), `?? fallback` for missing fields |
| Async fetch, 10 s timeout, `try-catch`, status codes | [`product_api.dart`](lib/services/product_api.dart): `.timeout(10 s)`, `200` → list, `404` / `5xx` / no network / timeout / bad JSON → `ProductApiException` with a Russian message |
| 3 UI states | `enum LoadState { loading, success, error }` + `switch` in `build`: spinner → `ListView.separated` (thumbnail, title, stars, price) → «Нет связи с магазином» with **Повторить** |
| Pull-to-refresh | `RefreshIndicator`; on failure the old list stays and a SnackBar explains why |
| Hero transition | `Hero(tag: 'product_image_${product.id}')` on the thumbnail and on carousel page 0 |
| Carousel with counter and dots | `PageView.builder` + «1 / 3» pill + `AnimatedContainer` dots (active one stretches into a lime pill) |
| Description, category badge, sticky «В корзину» | the button adds the product to the **LW9 global cart** (`CartProvider`), the AppBar badge updates live, then turns into «В корзине · открыть» |
| Share sheet with deep link | `showModalBottomSheet` with `narxoz://store/product/{id}` and **Копировать ссылку** (`Clipboard.setData`) |
| Prices | API prices are USD. Stipa works in ₸, so the main price is converted with a fixed demo rate `Product.usdToKzt = 520` and the original `$` price is shown next to it; the cart total stays in ₸ |
| Tests | `fromJson` int/double/null, 404/500/offline errors, loading → list → detail on 3 sizes, error → Повторить, pull-to-refresh, carousel swipe, add to cart, copy link ([`test/products_test.dart`](test/products_test.dart)), all with `MockClient`, no real network |

### Lab #11: Offline Notes & Settings Vault (SharedPreferences + JSON)

Screen **«Заметки»** ([`vault_screen.dart`](lib/screens/vault_screen.dart)), opened from **Профиль → Заметки и настройки**. Everything on it survives a force-quit.

| Requirement | Where |
|---|---|
| `shared_preferences: ^2.2.2` | `pubspec.yaml` |
| Load before `runApp()` | [`main.dart`](lib/main.dart): `WidgetsFlutterBinding.ensureInitialized()` → `await SharedPreferences.getInstance()` → `getBool('app_theme_dark_mode') ?? false`, `getString('user_display_name') ?? 'Guest User'` → `runApp(...)` |
| Dark mode switch, no flicker | `SwitchListTile` → `SettingsProvider.setDarkMode` → `setBool('app_theme_dark_mode', v)`. `MaterialApp` gets `theme` / `darkTheme` and `themeMode` from `SettingsProvider`, so the whole app switches. Neutral colors live in the `AppPalette` theme extension (`context.palette.card`), so every screen repaints. The value is in memory before `runApp()`, so the first frame is already in the saved theme |
| Username with «Сохранить» | `TextField` + button → `setString('user_display_name', name)`; header «Привет, {name}» with `'Guest User'` fallback; an empty name removes the key. The Профиль tab shows the same name |
| `NoteItem(id, title, dateText, isCompleted)` | [`note_item.dart`](lib/models/note_item.dart): `toJson()`, `factory NoteItem.fromJson(...)` with null-safe fallbacks |
| List ↔ one JSON string | [`notes_storage.dart`](lib/services/notes_storage.dart): `jsonEncode(notes.map((n) => n.toJson()).toList())` → `setString('saved_notes_list', ...)`; `jsonDecode` → `fromJson` on load, corrupted data → empty list |
| Add / toggle / delete synced to disk | `_addNote` (`insert(0, …)`, prepend), `_toggleNote` (checkbox or tap), `_deleteNote` (with «Отменить»), each followed by `NotesStorage.save` |
| Cold restart | add 2 notes, switch dark mode, save a name, swipe the app away, reopen → Профиль shows the name, «Заметки» opens dark with both notes and their checkboxes |
| Tests | JSON round trip and fallbacks, corrupted JSON, both themes on 3 sizes, simulated force-quit + relaunch, dark on the very first frame, delete + undo on disk, empty name → Guest User ([`test/vault_test.dart`](test/vault_test.dart)) |

### Lab #12: Advanced State Management with BLoC & Cubit

Screens **«Вход»** ([`login_screen.dart`](lib/lw12/screens/login_screen.dart)), **«Магазин»** ([`shop_catalog_screen.dart`](lib/lw12/screens/shop_catalog_screen.dart)) and **«Корзина»** ([`shop_cart_screen.dart`](lib/lw12/screens/shop_cart_screen.dart)), opened from **Профиль → Магазин с входом**. Everything lives in [`lib/lw12/`](lib/lw12), separate from the LW9 `CartProvider`, which keeps working as before.

| Requirement | Where |
|---|---|
| `flutter_bloc: ^8.1.3`, `equatable: ^2.0.5` | `pubspec.yaml` |
| `AuthCubit` with `AuthInitial`, `AuthLoading`, `AuthSuccess(username, email)`, `AuthError(message)` | [`auth_cubit.dart`](lib/lw12/bloc/auth/auth_cubit.dart), [`auth_state.dart`](lib/lw12/bloc/auth/auth_state.dart): `sealed class AuthState extends Equatable`, `props` overrides, `const` constructors |
| `login(email, password)` | `emit(AuthLoading())` → `Future.delayed(2 s)` → `AuthSuccess` for `student@narxoz.kz / 123456`, otherwise `AuthError` (empty fields, bad email, short password, wrong credentials); double taps during loading are ignored, `isClosed` check after the delay |
| `BlocConsumer<AuthCubit, AuthState>` | **listener** (with `listenWhen`): red floating `SnackBar` on `AuthError`, `pushReplacement` to the catalog on `AuthSuccess`. **builder**: fields disabled and the button replaced by `CircularProgressIndicator` during `AuthLoading` |
| `CartBloc` with `AddProductEvent(Product)`, `RemoveProductEvent(productId)`, `ClearCartEvent()` | [`cart_bloc.dart`](lib/lw12/bloc/cart/cart_bloc.dart), [`cart_event.dart`](lib/lw12/bloc/cart/cart_event.dart): one `on<Event>` handler per event, each emits a new state |
| `CartState(items, totalPrice, count)` | [`cart_state.dart`](lib/lw12/bloc/cart/cart_state.dart): `CartState.fromItems` derives total and count, `List.unmodifiable`, `CartItem(product, quantity)` |
| Catalog with «Добавить» | 6 offline student products in ₸ ([`shop_catalog.dart`](lib/lw12/data/shop_catalog.dart)); «в корзине: N» under each button via `BlocSelector` |
| Live AppBar badge | [`CartBadgeAction`](lib/lw12/widgets/cart_badge_action.dart): `BlocBuilder<CartBloc, CartState>` with `buildWhen: count changed` + Material `Badge`, on both the catalog and the cart route |
| Cart screen | lines with quantity and line total, 🗑 → `RemoveProductEvent`, «Итого», «Очистить всё» → `ClearCartEvent`, empty state |
| Providers | `MultiBlocProvider` above `MaterialApp` in [`main.dart`](lib/main.dart), so the three routes share one `AuthCubit` and one `CartBloc` |
| Tests | Cubit transitions for valid and every invalid input, Equatable equality, ignored double tap, every `CartBloc` event, immutability, SnackBar color/behavior + spinner, full login → catalog → cart flow with badge sync on 3 sizes, back navigation and logout ([`test/lw12_test.dart`](test/lw12_test.dart)) |

### Lab #13: Multimedia & Device Hardware (camera, gallery, GPS)

Screen **«📸 Narxoz Photo Journal»** ([`photo_diary_screen.dart`](lib/lw13/screens/photo_diary_screen.dart)), opened from **Профиль → Фотодневник**. Code in [`lib/lw13/`](lib/lw13).

| Requirement | Where |
|---|---|
| Android permissions | [`AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml): `CAMERA`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `READ_MEDIA_IMAGES` (+ `READ_EXTERNAL_STORAGE` up to API 32, camera feature not required) |
| iOS usage descriptions | [`Info.plist`](ios/Runner/Info.plist): `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSLocationWhenInUseUsageDescription`. permission_handler (Swift Package Manager) turns on its camera code from the same plist key |
| GPS off guard | `isLocationServiceEnabled()` first → dialog «GPS выключен» → **Включить GPS** calls `Geolocator.openLocationSettings()` |
| Camera + gallery | two buttons (Камера / Галерея) and a modal bottom sheet on the preview tap; `ImageSource.camera` / `ImageSource.gallery` ([`media_service.dart`](lib/lw13/services/media_service.dart)) |
| Compression | `pickImage(imageQuality: 80, maxWidth: 1080)`; the file is copied from the picker cache into the app documents folder, so it survives restarts |
| Camera runtime permission | `Permission.camera.request()` (permission_handler): denied → SnackBar, permanently denied → dialog → `openAppSettings()`. The gallery uses the system photo picker, which needs no permission |
| Preview | `ClipRRect(BorderRadius.circular(20))` + `Image.file(File(path))` ([`diary_photo.dart`](lib/lw13/widgets/diary_photo.dart)), camera icon placeholder when empty, broken-image icon if the file is gone |
| Location permission | `Geolocator.checkPermission()` → `requestPermission()` only if denied; `denied` → SnackBar, `deniedForever` → dialog → `Geolocator.openAppSettings()` ([`location_service.dart`](lib/lw13/services/location_service.dart)) |
| GPS fix | after every photo automatically and on **Определить GPS-координаты**; `CircularProgressIndicator` «Ищем спутники GPS…» while locking; `getCurrentPosition(locationSettings: LocationSettings(accuracy: LocationAccuracy.high, timeLimit: 20 s))` (`desiredAccuracy` is deprecated in geolocator 14) |
| Display | latitude / longitude (6 decimals), accuracy `± 12.4 м`, altitude, timestamp `2026-11-24 14:30:15` |
| Diary feed | caption field + **Сохранить в дневник** → list with thumbnail, caption, `43.2389° N, 76.8897° E`, time; swipe to delete with undo. Saved offline as JSON in SharedPreferences ([`diary_storage.dart`](lib/lw13/services/diary_storage.dart)) |
| No crashes | every hardware call returns a sealed result (`LocationFix / LocationServicesDisabled / LocationPermissionDenied / LocationPermissionDeniedForever / LocationFailure`, `MediaPicked / MediaCancelled / MediaPermissionDenied / MediaFailure`) and the screen `switch`es over it |
| Tests | JSON round trip, corrupted data, formatting, camera → auto GPS spinner → save → disk, gallery via the bottom sheet, cancel, GPS off dialog, denied / denied forever, camera denied, swipe + undo, both themes on 3 sizes, entry from Профиль ([`test/lw13_test.dart`](test/lw13_test.dart)); camera and GPS are fakes behind interfaces |

**Defense notes.**
- *Why `NSCameraUsageDescription` is mandatory on iOS.* iOS shows this text in the system permission prompt. If an app touches the camera without the key, iOS terminates it immediately (privacy crash), and App Store review rejects builds that use the camera without a clear reason.
- *"Don't ask again" on Android.* The system stops showing the dialog: `requestPermission()` returns at once with `deniedForever` / `permanentlyDenied` and no UI. The app can only explain why it needs the permission and send the user to the app settings (`openAppSettings()`), which is what the dialogs here do.

## Project structure

```
lib/
├── main.dart                     # App entry, MaterialApp + theme
├── lw12/                         # LW12 BLoC shop (self-contained)
│   ├── bloc/auth/                # AuthCubit + Equatable states
│   ├── bloc/cart/                # CartBloc, events, CartState
│   ├── data/shop_catalog.dart    # Offline products in ₸
│   ├── models/product.dart       # Equatable product
│   ├── screens/                  # Login (BlocConsumer), catalog, cart
│   └── widgets/cart_badge_action.dart # BlocBuilder badge
├── lw13/                         # LW13 geotagged photo diary
│   ├── models/diary_entry.dart   # Photo path, caption, time, coordinates
│   ├── services/                 # Camera/gallery, GPS, diary JSON storage
│   ├── screens/photo_diary_screen.dart
│   └── widgets/diary_photo.dart  # Image.file with a fallback
├── data/
│   └── mock_data.dart            # Mock expenses and budget (API in later milestones)
├── models/
│   ├── budget.dart               # Daily limit math
│   ├── category.dart             # Expense categories (label, icon, color)
│   ├── expense.dart              # Expense model
│   ├── note_item.dart            # Note + toJson/fromJson (LW11)
│   ├── product.dart              # Store product + fromJson (LW10)
│   └── planned_purchase.dart     # Catalog item for the cart (LW9)
├── services/
│   ├── notes_storage.dart        # Notes list <-> JSON in SharedPreferences (LW11)
│   └── product_api.dart          # http GET, timeout, errors (LW10)
├── providers/
│   ├── cart_provider.dart        # Global cart, ChangeNotifier (LW9)
│   └── settings_provider.dart    # Dark mode + username on disk (LW11)
├── screens/
│   ├── root_screen.dart          # BottomNavigationBar + shared state
│   ├── today_screen.dart         # Tab 1: feed
│   ├── overview_screen.dart      # Tab 2: stats by category
│   ├── favorites_screen.dart     # Tab 3: starred expenses
│   ├── history_screen.dart       # LW8: list/grid, refresh, swipe-to-delete
│   ├── catalog_screen.dart       # LW9: planned purchases + cart badge
│   ├── cart_screen.dart          # LW9: cart, total, clear all
│   ├── products_screen.dart      # LW10: API feed, 3 states, refresh
│   ├── product_detail_screen.dart # LW10: Hero, carousel, share sheet
│   ├── profile_screen.dart       # Tab 4: profile & settings
│   ├── vault_screen.dart         # LW11: offline notes, name, dark mode
│   ├── expense_detail_screen.dart
│   └── add_expense_screen.dart
├── theme/
│   └── app_theme.dart            # AppPalette (dark / light) + ThemeData
├── utils/
│   └── format.dart               # ₸ formatting, Russian dates and plurals
└── widgets/                      # Reusable UI pieces
    ├── budget_ring.dart          # CustomPainter ring
    ├── cart_badge_button.dart    # Cart icon with animated count (LW9)
    ├── category_chip.dart
    ├── category_tag.dart         # Colored category pill
    ├── expense_grid_card.dart    # Grid cell (LW8)
    ├── expense_image.dart        # Network image with fallback
    ├── expense_list_row.dart     # List row with avatar (LW8)
    ├── expense_tile.dart
    ├── favorite_button.dart      # StatefulWidget + setState
    ├── keypad.dart
    ├── product_image.dart        # Network photo with loading/error (LW10)
    ├── purchase_tile.dart        # Catalog / cart row (LW9)
    ├── rating_stars.dart         # ★★★★☆ + review count (LW10)
    ├── section_header.dart
    ├── stat_card.dart
    └── tag_chip.dart
```

## Getting started

Requirements: Flutter 3.32+ (Dart 3.8+), Xcode for the iOS Simulator.

```bash
git clone https://github.com/digitalvanhess/IOS-Final.git
cd IOS-Final
flutter pub get
open -a Simulator        # or start an Android emulator
flutter run
```

Run the checks:

```bash
flutter analyze
flutter test
```

## Roadmap

| Milestone | Plan |
|---|---|
| ✅ 1. MVP UI | Screens, navigation, local state |
| 2. REST API | Load and save expenses through an API, currency rates |
| 3. Database | Local storage so expenses survive restarts |
| 4. BLoC | ✅ LW12 login + cart on BLoC; next: move `RootScreen` state into BLoC |
| Final | Polish, animations, defense on Week 15 |

## Design

Figma mockup: [Stipa](https://www.figma.com/design/44LZ72awoqjPIbBBQ4QCl1/Untitled--Copy-?node-id=1-4)
