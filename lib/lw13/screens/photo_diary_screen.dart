import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../models/diary_entry.dart';
import '../services/diary_storage.dart';
import '../services/location_service.dart';
import '../services/media_service.dart';
import '../widgets/diary_photo.dart';

/// «Фотодневник» (LW13): Narxoz geotagged photo diary.
///
/// Camera / gallery via image_picker (compressed to quality 80, 1080 px),
/// GPS via geolocator, entries saved offline with [DiaryStorage].
/// Opened from the «Профиль» tab.
class PhotoDiaryScreen extends StatefulWidget {
  /// Hardware access. Tests pass fakes, the app uses the device.
  final MediaService? media;
  final LocationService? location;

  const PhotoDiaryScreen({super.key, this.media, this.location});

  @override
  State<PhotoDiaryScreen> createState() => _PhotoDiaryScreenState();
}

class _PhotoDiaryScreenState extends State<PhotoDiaryScreen> {
  late final MediaService _media = widget.media ?? DeviceMediaService();
  late final LocationService _location =
      widget.location ?? const DeviceLocationService();
  late final DiaryStorage _storage;
  late List<DiaryEntry> _entries;

  final _captionController = TextEditingController();

  String? _photoPath;
  LocationFix? _fix;

  /// When the photo was taken, shown before saving.
  DateTime? _capturedAt;
  bool _picking = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _storage = context.read<DiaryStorage>();
    _entries = _storage.load();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- photo

  Future<void> _chooseSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Сделать фото'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Выбрать из галереи'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source != null) await _pickPhoto(source);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_picking) return;
    setState(() => _picking = true);
    final result = await _media.pick(source);
    if (!mounted) return;
    setState(() => _picking = false);

    switch (result) {
      case MediaPicked(:final path):
        setState(() {
          _photoPath = path;
          _capturedAt = DateTime.now();
          _fix = null;
        });
        // Geotag right away: the place is where the photo was just taken.
        await _fetchLocation();
      case MediaCancelled():
        break;
      case MediaPermissionDenied(permanently: true):
        await _showSettingsDialog(
          title: 'Нет доступа к камере',
          message:
              'Доступ запрещён в настройках. Откройте настройки '
              'приложения и разрешите камеру.',
          onOpen: _media.openAppSettings,
        );
      case MediaPermissionDenied():
        _showSnack('Без доступа к камере снять фото нельзя');
      case MediaFailure(:final message):
        _showSnack(message);
    }
  }

  // ------------------------------------------------------------------ GPS

  Future<void> _fetchLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    final result = await _location.currentLocation();
    if (!mounted) return;
    setState(() => _locating = false);

    switch (result) {
      case LocationFix():
        setState(() => _fix = result);
      case LocationServicesDisabled():
        await _showSettingsDialog(
          title: 'GPS выключен',
          message:
              'Включите геолокацию на устройстве, чтобы отметить '
              'место снимка.',
          openLabel: 'Включить GPS',
          onOpen: _location.openLocationSettings,
        );
      case LocationPermissionDenied():
        _showSnack('Доступ к геолокации запрещён, запись будет без координат');
      case LocationPermissionDeniedForever():
        await _showSettingsDialog(
          title: 'Нет доступа к геолокации',
          message:
              'Вы запретили доступ навсегда. Разрешите геолокацию '
              'в настройках приложения.',
          onOpen: _location.openAppSettings,
        );
      case LocationFailure(:final message):
        _showSnack(message);
    }
  }

  // ---------------------------------------------------------------- diary

  void _saveEntry() {
    final path = _photoPath;
    if (path == null) return;
    final caption = _captionController.text.trim();
    final now = DateTime.now();
    final entry = DiaryEntry(
      id: now.microsecondsSinceEpoch.toString(),
      photoPath: path,
      caption: caption.isEmpty ? 'Без подписи' : caption,
      createdAt: _capturedAt ?? now,
      latitude: _fix?.latitude,
      longitude: _fix?.longitude,
      altitude: _fix?.altitude,
      accuracy: _fix?.accuracy,
    );
    setState(() {
      _entries.insert(0, entry);
      _photoPath = null;
      _capturedAt = null;
      _fix = null;
    });
    _storage.save(_entries);
    _captionController.clear();
    FocusScope.of(context).unfocus();
    _showSnack('Запись сохранена в дневник');
  }

  void _deleteEntry(DiaryEntry entry) {
    final index = _entries.indexOf(entry);
    setState(() => _entries.remove(entry));
    _storage.save(_entries);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Запись удалена'),
          action: SnackBarAction(
            label: 'Отменить',
            textColor: context.palette.accent,
            onPressed: () {
              setState(
                () => _entries.insert(index.clamp(0, _entries.length), entry),
              );
              _storage.save(_entries);
            },
          ),
        ),
      );
  }

  // ------------------------------------------------------------ feedback

  void _showSnack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _showSettingsDialog({
    required String title,
    required String message,
    required Future<bool> Function() onOpen,
    String openLabel = 'Открыть настройки',
  }) async {
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Не сейчас'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(openLabel),
          ),
        ],
      ),
    );
    if (open == true) await onOpen();
  }

  // ------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📸 Narxoz Photo Journal')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverList.list(
                    children: [
                      _Preview(
                        path: _photoPath,
                        loading: _picking,
                        onTap: _chooseSource,
                      ),
                      const SizedBox(height: 16),
                      _LocationCard(
                        fix: _fix,
                        locating: _locating,
                        capturedAt: _capturedAt,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonalIcon(
                              key: const ValueKey('take_photo'),
                              onPressed: _picking
                                  ? null
                                  : () => _pickPhoto(ImageSource.camera),
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: const Text('Камера'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              key: const ValueKey('pick_gallery'),
                              onPressed: _picking
                                  ? null
                                  : () => _pickPhoto(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Галерея'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const ValueKey('fetch_gps'),
                        onPressed: _locating ? null : _fetchLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Определить GPS-координаты'),
                      ),
                      const Divider(height: 40),
                      TextField(
                        key: const ValueKey('caption_field'),
                        controller: _captionController,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Подпись',
                          hintText: 'Campus Quad at Narxoz',
                          prefixIcon: Icon(Icons.edit_note),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const ValueKey('save_entry'),
                        onPressed: _photoPath == null ? null : _saveEntry,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Сохранить в дневник'),
                      ),
                      if (_photoPath == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Сначала сделайте или выберите фото',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.palette.textMuted,
                            ),
                          ),
                        ),
                      const SizedBox(height: 28),
                      Text(
                        '📜 Записи дневника (${_entries.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                if (_entries.isEmpty)
                  const SliverToBoxAdapter(child: _EmptyDiary())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.separated(
                      itemCount: _entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final entry = _entries[i];
                        return Dismissible(
                          key: ValueKey(entry.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _deleteEntry(entry),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          child: _EntryTile(entry: entry),
                        );
                      },
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

/// Rounded preview box: the photo via Image.file, or a camera placeholder.
class _Preview extends StatelessWidget {
  final String? path;
  final bool loading;
  final VoidCallback onTap;

  const _Preview({
    required this.path,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: palette.card,
          child: InkWell(
            key: const ValueKey('photo_preview'),
            onTap: loading ? null : onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (path != null)
                  DiaryPhoto(path: path!)
                else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_camera_outlined,
                        size: 56,
                        color: palette.textMuted,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Нажмите, чтобы добавить фото',
                        style: TextStyle(color: palette.textSecondary),
                      ),
                    ],
                  ),
                if (loading)
                  const ColoredBox(
                    color: Colors.black38,
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Latitude, longitude, accuracy and time. A spinner while the GPS locks.
class _LocationCard extends StatelessWidget {
  final LocationFix? fix;
  final bool locating;
  final DateTime? capturedAt;

  const _LocationCard({
    required this.fix,
    required this.locating,
    required this.capturedAt,
  });

  @override
  Widget build(BuildContext context) {
    final fix = this.fix;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: locating
            ? const Row(
                key: ValueKey('gps_loading'),
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  SizedBox(width: 14),
                  Expanded(child: Text('Ищем спутники GPS…')),
                ],
              )
            : Column(
                children: [
                  _InfoRow(
                    icon: '📍',
                    label: 'Широта',
                    value: fix?.latitude.toStringAsFixed(6) ?? '—',
                  ),
                  _InfoRow(
                    icon: '📍',
                    label: 'Долгота',
                    value: fix?.longitude.toStringAsFixed(6) ?? '—',
                  ),
                  _InfoRow(
                    icon: '🎯',
                    label: 'Точность',
                    value: fix == null
                        ? '—'
                        : '± ${fix.accuracy.toStringAsFixed(1)} м',
                  ),
                  _InfoRow(
                    icon: '⛰️',
                    label: 'Высота',
                    value: fix == null
                        ? '—'
                        : '${fix.altitude.toStringAsFixed(1)} м',
                  ),
                  _InfoRow(
                    icon: '⏰',
                    label: 'Время',
                    value: capturedAt == null ? '—' : Format.stamp(capturedAt!),
                  ),
                ],
              ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text(icon)),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(color: context.palette.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final DiaryEntry entry;

  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 64,
                height: 64,
                child: DiaryPhoto(path: entry.photoPath, cacheWidth: 192),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.hasLocation
                        ? Format.coordinates(entry.latitude!, entry.longitude!)
                        : 'Без координат',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: entry.hasLocation
                          ? palette.accentText
                          : palette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Format.stamp(entry.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDiary extends StatelessWidget {
  const _EmptyDiary();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 44,
            color: context.palette.textMuted,
          ),
          const SizedBox(height: 8),
          Text(
            'Пока нет записей',
            style: TextStyle(color: context.palette.textSecondary),
          ),
        ],
      ),
    );
  }
}
