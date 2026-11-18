import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/note_item.dart';

/// Saves the whole notes list as ONE JSON string under [notesKey] (LW11).
///
/// SharedPreferences only stores primitives (bool, int, double, String,
/// `List<String>`), so a `List<NoteItem>` goes through
/// `toJson()` -> `jsonEncode()` on the way in and
/// `jsonDecode()` -> `fromJson()` on the way out.
class NotesStorage {
  static const notesKey = 'saved_notes_list';

  final SharedPreferences _prefs;

  const NotesStorage(this._prefs);

  /// Reads the list from disk. The prefs instance is already loaded in
  /// `main()`, so this is synchronous and the list shows on the first frame.
  List<NoteItem> load() {
    final raw = _prefs.getString(notesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => NoteItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupted data must not crash the app: start with an empty list.
      return [];
    }
  }

  /// Writes the whole list back after every add / toggle / delete.
  Future<bool> save(List<NoteItem> notes) {
    final raw = jsonEncode(notes.map((n) => n.toJson()).toList());
    return _prefs.setString(notesKey, raw);
  }
}
