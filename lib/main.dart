import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final displayName =
      prefs.getString(SettingsProvider.displayNameKey) ??
      SettingsProvider.defaultName;

  runApp(
    StipaApp(
      settings: SettingsProvider(
        prefs,
        isDarkMode: isDarkMode,
        displayName: displayName,
      ),
      notesStorage: NotesStorage(prefs),
    ),
  );
}

class StipaApp extends StatelessWidget {
  final SettingsProvider settings;
  final NotesStorage notesStorage;

  const StipaApp({
    super.key,
    required this.settings,
    required this.notesStorage,
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
      ],
      child: MaterialApp(
        title: 'Stipa',
        debugShowCheckedModeBanner: false,
        // The Stipa screens are drawn in the dark palette from the Figma
        // mockup. The LW11 dark mode switch themes the «Заметки» screen
        // (see VaultScreen).
        theme: AppTheme.dark,
        home: const RootScreen(),
      ),
    );
  }
}
