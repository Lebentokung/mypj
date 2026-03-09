import 'package:latlong2/latlong.dart';

class MapPin {
  final String id;
  final String userId;
  final LatLng location;
  final String title;
  final String description;
  final List<String> imagePaths;
  final DateTime createdAt;

  MapPin({
    required this.id,
    required this.userId,
    required this.location,
    required this.title,
    required this.description,
    required this.imagePaths,
    required this.createdAt,
  });

  MapPin copyWith({
    String? id,
    String? userId,
    LatLng? location,
    String? title,
    String? description,
    List<String>? imagePaths,
    DateTime? createdAt,
  }) {
    return MapPin(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      location: location ?? this.location,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePaths: imagePaths ?? this.imagePaths,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MapPin.fromMap(String id, Map<String, dynamic> map) {
    return MapPin(
      id: id,
      userId: (map['user_id'] as String?) ?? '',
      location: LatLng(
        (map['lat'] as num?)?.toDouble() ?? 0,
        (map['lng'] as num?)?.toDouble() ?? 0,
      ),
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      imagePaths: List<String>.from((map['image_urls'] as List?) ?? const []),
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'lat': location.latitude,
      'lng': location.longitude,
      'title': title,
      'description': description,
      'image_urls': imagePaths,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
