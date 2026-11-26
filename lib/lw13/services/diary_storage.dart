import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/diary_entry.dart';

/// Offline diary: the entries list as ONE JSON string, same approach as the
/// LW11 [NotesStorage]. The photos are files, only their paths are here.
class DiaryStorage {
  static const entriesKey = 'photo_diary_entries';

  final SharedPreferences _prefs;

  const DiaryStorage(this._prefs);

  List<DiaryEntry> load() {
    final raw = _prefs.getString(entriesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> save(List<DiaryEntry> entries) {
    final raw = jsonEncode(entries.map((e) => e.toJson()).toList());
    return _prefs.setString(entriesKey, raw);
  }
}
