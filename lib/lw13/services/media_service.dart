import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Outcome of taking or picking one photo.
sealed class MediaResult {
  const MediaResult();
}

class MediaPicked extends MediaResult {
  final String path;

  const MediaPicked(this.path);
}

/// The user closed the camera / gallery without a photo.
class MediaCancelled extends MediaResult {
  const MediaCancelled();
}

class MediaPermissionDenied extends MediaResult {
  /// True after "Don't ask again": only the app settings can fix it.
  final bool permanently;

  const MediaPermissionDenied({required this.permanently});
}

class MediaFailure extends MediaResult {
  final String message;

  const MediaFailure(this.message);
}

/// Camera and gallery access. An interface, so widget tests use a fake.
abstract interface class MediaService {
  Future<MediaResult> pick(ImageSource source);

  Future<bool> openAppSettings();
}

class DeviceMediaService implements MediaService {
  /// Compression from the task: JPEG quality 80, at most 1080 px wide.
  /// A 12 MP photo (~4 MB) becomes ~200–300 KB.
  static const imageQuality = 80;
  static const maxWidth = 1080.0;

  final ImagePicker _picker;

  DeviceMediaService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  @override
  Future<MediaResult> pick(ImageSource source) async {
    // Camera needs a runtime permission. The gallery opens the system photo
    // picker (PHPicker on iOS, Photo Picker on Android 13+), which runs
    // outside the app and needs no permission.
    if (source == ImageSource.camera) {
      final status = await ph.Permission.camera.request();
      if (status.isPermanentlyDenied || status.isRestricted) {
        return const MediaPermissionDenied(permanently: true);
      }
      if (!status.isGranted) {
        return const MediaPermissionDenied(permanently: false);
      }
    }

    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
      );
      if (file == null) return const MediaCancelled();
      return MediaPicked(await _keep(file));
    } on PlatformException catch (e) {
      // iOS reports a denied camera / library as `*_access_denied`.
      if (e.code.contains('access_denied')) {
        return const MediaPermissionDenied(permanently: true);
      }
      return MediaFailure(e.message ?? 'Не удалось открыть камеру');
    } catch (_) {
      return const MediaFailure('Не удалось сохранить фото');
    }
  }

  /// image_picker returns a file in the temp/cache folder, which the OS may
  /// clear. The diary must survive restarts, so the photo is copied into
  /// the app documents folder.
  Future<String> _keep(XFile file) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/photo_diary');
    await dir.create(recursive: true);
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final saved = await File(file.path).copy('${dir.path}/$name');
    return saved.path;
  }

  @override
  Future<bool> openAppSettings() => ph.openAppSettings();
}
