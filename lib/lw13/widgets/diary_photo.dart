import 'dart:io';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// A photo from the local filesystem: `Image.file(File(path))`.
///
/// If the file is gone (app reinstalled, storage cleared), shows an icon
/// instead of the red error box.
class DiaryPhoto extends StatelessWidget {
  final String path;

  /// Decode size for thumbnails, so the list does not keep full 1080 px
  /// bitmaps in memory.
  final int? cacheWidth;

  const DiaryPhoto({super.key, required this.path, this.cacheWidth});

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      errorBuilder: (context, _, _) => ColoredBox(
        color: context.palette.cardLight,
        child: Icon(
          Icons.broken_image_outlined,
          color: context.palette.textMuted,
        ),
      ),
    );
  }
}
