import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'lw12/bloc/auth/auth_cubit.dart';
import 'lw12/bloc/cart/cart_bloc.dart';
import 'lw13/services/diary_storage.dart';
import 'providers/cart_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/root_screen.dart';
import 'services/notes_storage.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Plugins (SharedPreferences uses a platform channel) need the binding
  // before runApp().
  WidgetsFlutterBinding.ensureInitialized();

  // LW11: read the disk BEFORE the first frame. If we loaded it later in
  // initState, the first frame would use the default theme and then
  // "flash" into dark mode.
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool(SettingsProvider.darkModeKey) ?? false;
  final isVice = prefs.getBool(SettingsProvider.viceKey) ?? false;
  final displayName =
      prefs.getString(SettingsProvider.displayNameKey) ??
      SettingsProvider.defaultName;

  runApp(
    StipaApp(
      settings: SettingsProvider(
        prefs,
        isDarkMode: isDarkMode,
        isVice: isVice,
        displayName: displayName,
      ),
      notesStorage: NotesStorage(prefs),
      diaryStorage: DiaryStorage(prefs),
    ),
  );
}

class StipaApp extends StatelessWidget {
  final SettingsProvider settings;
  final NotesStorage notesStorage;

  /// LW13 photo diary entries.
  final DiaryStorage diaryStorage;

  /// LW12 fake login round trip. Tests can shorten it.
  final Duration authDelay;

  const StipaApp({
    super.key,
    required this.settings,
    required this.notesStorage,
    required this.diaryStorage,
    this.authDelay = const Duration(seconds: 2),
  });

  @override
  Widget build(BuildContext context) {
    // Above MaterialApp, so every pushed route sees the same cart and
    // settings.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider.value(value: settings),
        Provider.value(value: notesStorage),
        Provider.value(value: diaryStorage),
      ],
      // LW12: the BLoC shop has its own AuthCubit and CartBloc, separate
      // from the LW9 CartProvider. Also above MaterialApp, so the login,
      // catalog and cart routes share one instance of each.
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthCubit(delay: authDelay)),
          BlocProvider(create: (_) => CartBloc()),
        ],
        child: Selector<SettingsProvider, (bool, bool)>(
          selector: (_, s) => (s.isDarkMode, s.showsVice),
          // LW11: the dark mode switch themes the whole app. The value is
          // already in memory (read in main()), so the first frame is drawn
          // in the saved theme, with no light -> dark flash.
          builder: (_, mode, child) => MaterialApp(
            title: 'Stipa',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            // Vice Night replaces the dark theme while its switch is on.
            darkTheme: mode.$2 ? AppTheme.vice : AppTheme.dark,
            themeMode: mode.$1 ? ThemeMode.dark : ThemeMode.light,
            home: child,
          ),
          child: const RootScreen(),
        ),
      ),
    );
  }
}
