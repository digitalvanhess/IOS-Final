import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme and username, persisted with SharedPreferences (LW11).
///
/// The initial values are read in `main()` BEFORE `runApp()`, so the very
/// first frame is already drawn with the saved theme and name.
class SettingsProvider extends ChangeNotifier {
  static const darkModeKey = 'app_theme_dark_mode';
  static const displayNameKey = 'user_display_name';

  /// Vice Night neon skin on top of dark mode (just for fun).
  static const viceKey = 'app_theme_vice';
  static const defaultName = 'Guest User';

  final SharedPreferences _prefs;
  bool _isDarkMode;
  bool _isVice;
  String _displayName;

  SettingsProvider(
    this._prefs, {
    required bool isDarkMode,
    required String displayName,
    bool isVice = false,
  }) : _isDarkMode = isDarkMode,
       _isVice = isVice,
       _displayName = displayName;

  /// Reads both values from an already loaded prefs instance, with the
  /// null-aware fallbacks for the very first launch.
  factory SettingsProvider.fromPrefs(SharedPreferences prefs) {
    return SettingsProvider(
      prefs,
      isDarkMode: prefs.getBool(darkModeKey) ?? false,
      displayName: prefs.getString(displayNameKey) ?? defaultName,
      isVice: prefs.getBool(viceKey) ?? false,
    );
  }

  bool get isDarkMode => _isDarkMode;

  /// The skin is a dark theme, so it only shows while dark mode is on. The
  /// choice is kept when dark mode goes off and comes back with it.
  bool get isVice => _isVice;
  bool get showsVice => _isDarkMode && _isVice;
  String get displayName => _displayName;

  /// True when the user has saved a name (not the 'Guest User' fallback).
  bool get hasCustomName => _prefs.getString(displayNameKey) != null;

  /// UI updates at once, then the value goes to disk.
  Future<void> setDarkMode(bool value) async {
    if (value == _isDarkMode) return;
    _isDarkMode = value;
    notifyListeners();
    await _prefs.setBool(darkModeKey, value);
  }

  Future<void> setVice(bool value) async {
    if (value == _isVice) return;
    _isVice = value;
    notifyListeners();
    await _prefs.setBool(viceKey, value);
  }

  /// Saves the trimmed name. An empty name removes the key, so the header
  /// falls back to 'Guest User' again.
  Future<void> saveDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      await _prefs.remove(displayNameKey);
      _displayName = defaultName;
    } else {
      await _prefs.setString(displayNameKey, trimmed);
      _displayName = trimmed;
    }
    notifyListeners();
  }
}
