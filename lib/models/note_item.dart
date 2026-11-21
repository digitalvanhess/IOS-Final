/// One note in the LW11 offline vault.
///
/// Saved to disk as part of a JSON array:
/// `[{"id": "...", "title": "...", "dateText": "...", "isCompleted": false}]`
class NoteItem {
  final String id;
  final String title;
  final String dateText;
  final bool isCompleted;

  const NoteItem({
    required this.id,
    required this.title,
    required this.dateText,
    this.isCompleted = false,
  });

  /// Object -> Map. `jsonEncode` then turns a list of these maps into one
  /// String that SharedPreferences can store.
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'dateText': dateText,
    'isCompleted': isCompleted,
  };

  /// Map (from `jsonDecode`) -> object. Null-safe: a missing or broken field
  /// falls back to a default instead of crashing the app on start.
  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      dateText: json['dateText'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  NoteItem copyWith({bool? isCompleted}) => NoteItem(
    id: id,
    title: title,
    dateText: dateText,
    isCompleted: isCompleted ?? this.isCompleted,
  );
}
