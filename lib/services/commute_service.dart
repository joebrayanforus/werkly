import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CommuteEstimate {
  const CommuteEstimate({
    required this.durationMinutes,
    required this.distanceKm,
    required this.calculatedAt,
    required this.routeUrl,
  });

  final int durationMinutes;
  final double distanceKm;
  final DateTime calculatedAt;
  final Uri routeUrl;

  String get label =>
      '$durationMinutes min · ${distanceKm.toStringAsFixed(0)} km';

  Map<String, dynamic> toJson() => {
    'duration_minutes': durationMinutes,
    'distance_km': distanceKm,
    'calculated_at': calculatedAt.toUtc().toIso8601String(),
    'route_url': routeUrl.toString(),
  };

  factory CommuteEstimate.fromJson(Map<String, dynamic> json) =>
      CommuteEstimate(
        durationMinutes: (json['duration_minutes'] as num?)?.round() ?? 0,
        distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
        calculatedAt:
            DateTime.tryParse(json['calculated_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        routeUrl:
            Uri.tryParse(json['route_url'] as String? ?? '') ?? Uri.parse(''),
      );
}

class CommuteService {
  CommuteService({http.Client? client, Uri? endpoint})
    : _client = client ?? http.Client(),
      _endpoint = endpoint ?? Uri.parse('https://router.project-osrm.org');

  static const _cachePrefix = 'werkly_commute_v1_';
  static const _cacheTtl = Duration(days: 7);

  final http.Client _client;
  final Uri _endpoint;

  void close() => _client.close();

  Future<CommuteEstimate?> estimate({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
    bool force = false,
  }) async {
    final cacheKey = _key(fromLatitude, fromLongitude, toLatitude, toLongitude);
    final preferences = await SharedPreferences.getInstance();
    if (!force) {
      final cached = _decode(preferences.getString(cacheKey));
      if (cached != null &&
          DateTime.now().toUtc().difference(cached.calculatedAt.toUtc()) <
              _cacheTtl) {
        return cached;
      }
    }

    final coordinates =
        '${fromLongitude.toStringAsFixed(6)},${fromLatitude.toStringAsFixed(6)};'
        '${toLongitude.toStringAsFixed(6)},${toLatitude.toStringAsFixed(6)}';
    final uri = _endpoint.replace(
      path: '${_endpoint.path}/route/v1/driving/$coordinates',
      queryParameters: const {'overview': 'false', 'steps': 'false'},
    );
    try {
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body);
      if (json is! Map || json['code'] != 'Ok') return null;
      final routes = json['routes'];
      if (routes is! List || routes.isEmpty || routes.first is! Map) {
        return null;
      }
      final route = Map<String, dynamic>.from(routes.first as Map);
      final durationSeconds = (route['duration'] as num?)?.toDouble();
      final distanceMeters = (route['distance'] as num?)?.toDouble();
      if (durationSeconds == null ||
          durationSeconds <= 0 ||
          distanceMeters == null ||
          distanceMeters <= 0) {
        return null;
      }
      final estimate = CommuteEstimate(
        durationMinutes: (durationSeconds / 60).round().clamp(1, 1440),
        distanceKm: distanceMeters / 1000,
        calculatedAt: DateTime.now().toUtc(),
        routeUrl: _openStreetMapDirections(
          fromLatitude,
          fromLongitude,
          toLatitude,
          toLongitude,
        ),
      );
      await preferences.setString(cacheKey, jsonEncode(estimate.toJson()));
      return estimate;
    } catch (_) {
      return null;
    }
  }

  CommuteEstimate? _decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;
    try {
      final value = jsonDecode(encoded);
      return value is Map
          ? CommuteEstimate.fromJson(Map<String, dynamic>.from(value))
          : null;
    } catch (_) {
      return null;
    }
  }

  String _key(double fromLat, double fromLon, double toLat, double toLon) =>
      '$_cachePrefix${fromLat.toStringAsFixed(3)}_'
      '${fromLon.toStringAsFixed(3)}_'
      '${toLat.toStringAsFixed(3)}_'
      '${toLon.toStringAsFixed(3)}';

  Uri _openStreetMapDirections(
    double fromLat,
    double fromLon,
    double toLat,
    double toLon,
  ) => Uri.https('www.openstreetmap.org', '/directions', {
    'engine': 'fossgis_osrm_car',
    'route': '$fromLat,$fromLon;$toLat,$toLon',
  });
}
