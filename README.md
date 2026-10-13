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

## Project structure

```
lib/
├── main.dart                     # App entry, MaterialApp + theme
├── data/
│   └── mock_data.dart            # Mock expenses and budget (API in later milestones)
├── models/
│   ├── budget.dart               # Daily limit math
│   ├── category.dart             # Expense categories (label, icon, color)
│   └── expense.dart              # Expense model
├── screens/
│   ├── root_screen.dart          # BottomNavigationBar + shared state
│   ├── today_screen.dart         # Tab 1: feed
│   ├── overview_screen.dart      # Tab 2: stats by category
│   ├── favorites_screen.dart     # Tab 3: starred expenses
│   ├── profile_screen.dart       # Tab 4: profile & settings
│   ├── expense_detail_screen.dart
│   └── add_expense_screen.dart
├── theme/
│   └── app_theme.dart            # Colors and ThemeData
├── utils/
│   └── format.dart               # ₸ formatting, Russian dates and plurals
└── widgets/                      # Reusable UI pieces
    ├── budget_ring.dart          # CustomPainter ring
    ├── category_chip.dart
    ├── expense_image.dart        # Network image with fallback
    ├── expense_tile.dart
    ├── favorite_button.dart      # StatefulWidget + setState
    ├── keypad.dart
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
| 4. BLoC | Move state out of `RootScreen` into BLoC |
| Final | Polish, animations, defense on Week 15 |

## Design

Figma mockup: [Stipa](https://www.figma.com/design/44LZ72awoqjPIbBBQ4QCl1/Untitled--Copy-?node-id=1-4)
