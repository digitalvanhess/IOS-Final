/// One entry of the geotagged photo diary (LW13).
///
/// Stores only metadata: the photo itself stays on disk in the app
/// documents folder, the entry keeps its [photoPath].
class DiaryEntry {
  final String id;
  final String photoPath;
  final String caption;
  final DateTime createdAt;

  /// Null when the user saved the photo without a GPS fix.
  final double? latitude;
  final double? longitude;
  final double? altitude;

  /// GPS accuracy radius in meters.
  final double? accuracy;

  const DiaryEntry({
    required this.id,
    required this.photoPath,
    required this.caption,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.altitude,
    this.accuracy,
  });

  bool get hasLocation => latitude != null && longitude != null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'photoPath': photoPath,
    'caption': caption,
    'createdAt': createdAt.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'accuracy': accuracy,
  };

  /// Null-safe parsing: a broken field gives a fallback, not a crash.
  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
    id: json['id'] as String? ?? '',
    photoPath: json['photoPath'] as String? ?? '',
    caption: json['caption'] as String? ?? '',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    altitude: (json['altitude'] as num?)?.toDouble(),
    accuracy: (json['accuracy'] as num?)?.toDouble(),
  );
}
