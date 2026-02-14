import 'package:latlong2/latlong.dart';

class MapPin {
  final String id;
  final LatLng location;
  final String title;
  final String description;
  final List<String> imagePaths;
  final DateTime createdAt;

  MapPin({
    required this.id,
    required this.location,
    required this.title,
    required this.description,
    required this.imagePaths,
    required this.createdAt,
  });

  MapPin copyWith({
    String? id,
    LatLng? location,
    String? title,
    String? description,
    List<String>? imagePaths,
    DateTime? createdAt,
  }) {
    return MapPin(
      id: id ?? this.id,
      location: location ?? this.location,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePaths: imagePaths ?? this.imagePaths,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
