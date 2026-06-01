import 'dart:convert';

import 'package:http/http.dart' as http;

class HealthPlace {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? rating;
  final bool? openNow;

  const HealthPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.rating,
    this.openNow,
  });

  factory HealthPlace.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? {};
    final displayName = json['displayName'] as Map<String, dynamic>? ?? {};
    final regularOpeningHours =
        json['regularOpeningHours'] as Map<String, dynamic>?;

    return HealthPlace(
      id: (json['id'] ?? json['name'] ?? '').toString(),
      name: (displayName['text'] ?? 'Unnamed place').toString(),
      address: (json['formattedAddress'] ?? '').toString(),
      latitude: (location['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (location['longitude'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble(),
      openNow: regularOpeningHours?['openNow'] as bool?,
    );
  }
}

class PlacesService {
  static const apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  Future<List<HealthPlace>> searchNearby({
    required double latitude,
    required double longitude,
    required String type,
    int radiusMeters = 5000,
  }) async {
    if (apiKey.isEmpty) {
      throw const PlacesException(
        'GOOGLE_MAPS_API_KEY is missing. Start Flutter with --dart-define.',
      );
    }

    final response = await http.post(
      Uri.parse('https://places.googleapis.com/v1/places:searchNearby'),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask':
            'places.id,places.name,places.displayName,places.formattedAddress,places.location,places.rating,places.regularOpeningHours',
      },
      body: jsonEncode({
        'includedTypes': [type],
        'maxResultCount': 10,
        'rankPreference': 'DISTANCE',
        'locationRestriction': {
          'circle': {
            'center': {'latitude': latitude, 'longitude': longitude},
            'radius': radiusMeters.toDouble(),
          },
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PlacesException(
        'Places request failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final places = (data['places'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(HealthPlace.fromJson)
        .where((place) => place.latitude != 0 && place.longitude != 0)
        .toList();
    return places;
  }

  String staticMapUrl({
    required double latitude,
    required double longitude,
    required List<HealthPlace> places,
  }) {
    final markers = places
        .take(8)
        .map((place) {
          return 'markers=color:red%7C${place.latitude},${place.longitude}';
        })
        .join('&');

    return 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$latitude,$longitude'
        '&zoom=14'
        '&size=900x360'
        '&scale=2'
        '&markers=color:blue%7Clabel:U%7C$latitude,$longitude'
        '${markers.isEmpty ? '' : '&$markers'}'
        '&key=$apiKey';
  }
}

class PlacesException implements Exception {
  final String message;

  const PlacesException(this.message);

  @override
  String toString() => message;
}
