import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note_item.dart';
import '../providers/settings_provider.dart';
import '../services/notes_storage.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

/// «Заметки» (LW11): offline-first notes and settings vault.
///
/// Everything on this screen lives on disk in SharedPreferences:
/// - dark mode switch -> `app_theme_dark_mode` (bool)
/// - username -> `user_display_name` (String, 'Guest User' fallback)
/// - notes -> `saved_notes_list` (one JSON string, see [NotesStorage])
///
/// Opened from the «Профиль» tab.
class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select<SettingsProvider, bool>((s) => s.isDarkMode);
    // The saved theme is already known (read in main()), so the first frame
    // uses it: no light -> dark flash.
    return Theme(
      data: isDark ? AppTheme.dark : AppTheme.light,
      child: const _VaultView(),
    );
  }
}

class _VaultView extends StatefulWidget {
  const _VaultView();

  @override
  State<_VaultView> createState() => _VaultViewState();
}

class _VaultViewState extends State<_VaultView> {
  late final NotesStorage _storage;
  late List<NoteItem> _notes;
  late final TextEditingController _nameController;
  final _noteController = TextEditingController();
  final _noteFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _storage = context.read<NotesStorage>();
    // Synchronous read: the prefs instance was loaded before runApp().
    _notes = _storage.load();

    final settings = context.read<SettingsProvider>();
    _nameController = TextEditingController(
      text: settings.hasCustomName ? settings.displayName : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- notes

  /// Prepend -> jsonEncode -> save to disk.
  void _addNote() {
    final title = _noteController.text.trim();
    if (title.isEmpty) return;
    final now = DateTime.now();
    final note = NoteItem(
      id: now.microsecondsSinceEpoch.toString(),
      title: title,
      dateText: '${Format.dayMonth(now)}, ${Format.time(now)}',
    );
    setState(() => _notes.insert(0, note));
    _storage.save(_notes);
    _noteController.clear();
    _noteFocus.requestFocus();
  }

  void _toggleNote(NoteItem note) {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index == -1) return;
    setState(
      () => _notes[index] = note.copyWith(isCompleted: !note.isCompleted),
    );
    _storage.save(_notes);
  }

  void _deleteNote(NoteItem note) {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index == -1) return;
    setState(() => _notes.removeAt(index));
    _storage.save(_notes);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Заметка «${note.title}» удалена'),
          action: SnackBarAction(
            label: 'Отменить',
            textColor: AppColors.accent,
            onPressed: () {
              if (!mounted) return;
              setState(
                () => _notes.insert(index.clamp(0, _notes.length), note),
              );
              _storage.save(_notes);
            },
          ),
        ),
      );
  }

  // ------------------------------------------------------------- username

  Future<void> _saveName() async {
    FocusScope.of(context).unfocus();
    final settings = context.read<SettingsProvider>();
    await settings.saveDisplayName(_nameController.text);
    if (!mounted) return;
    if (!settings.hasCustomName) _nameController.clear();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Имя сохранено: ${settings.displayName}')),
      );
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final scheme = Theme.of(context).colorScheme;
    final done = _notes.where((n) => n.isCompleted).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Заметки')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: ConstrainedBox(
            // Phones use the full width; on iPad the column stays readable.
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                _Header(name: settings.displayName),
                const SizedBox(height: 20),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile(
                    key: const ValueKey('dark_mode_switch'),
                    value: settings.isDarkMode,
                    onChanged: settings.setDarkMode,
                    secondary: Icon(
                      settings.isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: scheme.onSurfaceVariant,
                    ),
                    title: const Text('Тёмная тема'),
                    subtitle: const Text('Сохраняется на устройстве'),
                  ),
                ),
                const SizedBox(height: 12),
                _NameCard(controller: _nameController, onSave: _saveName),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Мои заметки',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    if (_notes.isNotEmpty)
                      Text(
                        '$done из ${_notes.length}',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _NoteInput(
                  controller: _noteController,
                  focusNode: _noteFocus,
                  onAdd: _addNote,
                ),
                const SizedBox(height: 12),
                if (_notes.isEmpty)
                  const _EmptyNotes()
                else
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < _notes.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              thickness: 0.5,
                              color: scheme.outlineVariant,
                            ),
                          _NoteRow(
                            key: ValueKey(_notes[i].id),
                            note: _notes[i],
                            onToggle: () => _toggleNote(_notes[i]),
                            onDelete: () => _deleteNote(_notes[i]),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// «Привет, Иван» with the first letter in a lime circle.
class _Header extends StatelessWidget {
  final String name;

  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.accentSoft,
          child: Text(
            name.characters.first.toUpperCase(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.accentDark,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Привет, $name',
                key: const ValueKey('vault_header_name'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Работает без интернета',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NameCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSave;

  const _NameCard({required this.controller, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('name_field'),
                controller: controller,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onSave(),
                decoration: const InputDecoration(
                  labelText: 'Имя пользователя',
                  hintText: SettingsProvider.defaultName,
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onAdd;

  const _NoteInput({
    required this.controller,
    required this.focusNode,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey('note_field'),
            controller: controller,
            focusNode: focusNode,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onAdd(),
            decoration: const InputDecoration(
              hintText: 'Новая заметка',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filled(
          onPressed: onAdd,
          tooltip: 'Добавить заметку',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black,
            fixedSize: const Size(48, 48),
          ),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _NoteRow extends StatelessWidget {
  final NoteItem note;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _NoteRow({
    super.key,
    required this.note,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onToggle,
      contentPadding: const EdgeInsets.only(left: 4, right: 4),
      leading: Checkbox(value: note.isCompleted, onChanged: (_) => onToggle()),
      title: Text(
        note.title,
        style: TextStyle(
          color: note.isCompleted ? scheme.onSurfaceVariant : scheme.onSurface,
          decoration: note.isCompleted ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        note.dateText,
        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
      ),
      trailing: IconButton(
        onPressed: onDelete,
        tooltip: 'Удалить заметку',
        icon: Icon(Icons.delete_outline, color: scheme.onSurfaceVariant),
      ),
    );
  }
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.sticky_note_2_outlined, size: 48, color: scheme.outline),
          const SizedBox(height: 12),
          Text(
            'Заметок пока нет',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Они сохранятся даже после перезапуска',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
