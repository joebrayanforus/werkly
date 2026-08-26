import 'dart:math' as math;

class GermanCity {
  const GermanCity(this.name, this.state, this.latitude, this.longitude);

  final String name;
  final String state;
  final double latitude;
  final double longitude;

  String get label => '$name · $state';
}

class GermanCityService {
  const GermanCityService._();

  static List<GermanCity> search(String query, {int limit = 6}) {
    final normalized = _normalize(query);
    final literalQuery = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];
    final matches =
        cities
            .where(
              (city) =>
                  _normalize(city.name).contains(normalized) ||
                  _normalize(city.state).contains(normalized),
            )
            .toList()
          ..sort((a, b) {
            final aLiteralStarts = a.name.toLowerCase().startsWith(
              literalQuery,
            );
            final bLiteralStarts = b.name.toLowerCase().startsWith(
              literalQuery,
            );
            if (aLiteralStarts != bLiteralStarts) {
              return aLiteralStarts ? -1 : 1;
            }
            final aStarts = _normalize(a.name).startsWith(normalized);
            final bStarts = _normalize(b.name).startsWith(normalized);
            if (aStarts != bStarts) return aStarts ? -1 : 1;
            return a.name.compareTo(b.name);
          });
    return matches.take(limit).toList();
  }

  static GermanCity? exact(String name) {
    final normalized = _normalize(name);
    for (final city in cities) {
      if (_normalize(city.name) == normalized) return city;
    }
    return null;
  }

  static ({GermanCity city, double distanceKm}) nearest(
    double latitude,
    double longitude,
  ) {
    var nearestCity = cities.first;
    var nearestDistance = double.infinity;
    for (final city in cities) {
      final distance = _distanceKm(
        latitude,
        longitude,
        city.latitude,
        city.longitude,
      );
      if (distance < nearestDistance) {
        nearestCity = city;
        nearestDistance = distance;
      }
    }
    return (city: nearestCity, distanceKm: nearestDistance);
  }

  static double _distanceKm(
    double latitudeA,
    double longitudeA,
    double latitudeB,
    double longitudeB,
  ) {
    const radius = 6371.0;
    double radians(double value) => value * math.pi / 180;
    final dLatitude = radians(latitudeB - latitudeA);
    final dLongitude = radians(longitudeB - longitudeA);
    final a =
        math.sin(dLatitude / 2) * math.sin(dLatitude / 2) +
        math.cos(radians(latitudeA)) *
            math.cos(radians(latitudeB)) *
            math.sin(dLongitude / 2) *
            math.sin(dLongitude / 2);
    return radius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('ä', 'a')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ß', 'ss')
      .replaceAll('é', 'e');

  static const cities = <GermanCity>[
    GermanCity('Aachen', 'Nordrhein-Westfalen', 50.7753, 6.0839),
    GermanCity('Augsburg', 'Bayern', 48.3705, 10.8978),
    GermanCity('Bamberg', 'Bayern', 49.8988, 10.9028),
    GermanCity('Bayreuth', 'Bayern', 49.9456, 11.5713),
    GermanCity('Bergisch Gladbach', 'Nordrhein-Westfalen', 50.9923, 7.1286),
    GermanCity('Berlin', 'Berlin', 52.5200, 13.4050),
    GermanCity('Bielefeld', 'Nordrhein-Westfalen', 52.0302, 8.5325),
    GermanCity('Bochum', 'Nordrhein-Westfalen', 51.4818, 7.2162),
    GermanCity('Bonn', 'Nordrhein-Westfalen', 50.7374, 7.0982),
    GermanCity('Bottrop', 'Nordrhein-Westfalen', 51.5239, 6.9285),
    GermanCity('Braunschweig', 'Niedersachsen', 52.2689, 10.5268),
    GermanCity('Bremen', 'Bremen', 53.0793, 8.8017),
    GermanCity('Bremerhaven', 'Bremen', 53.5396, 8.5809),
    GermanCity('Chemnitz', 'Sachsen', 50.8278, 12.9214),
    GermanCity('Cottbus', 'Brandenburg', 51.7563, 14.3329),
    GermanCity('Darmstadt', 'Hessen', 49.8728, 8.6512),
    GermanCity('Dortmund', 'Nordrhein-Westfalen', 51.5136, 7.4653),
    GermanCity('Dresden', 'Sachsen', 51.0504, 13.7373),
    GermanCity('Duisburg', 'Nordrhein-Westfalen', 51.4344, 6.7623),
    GermanCity('Düsseldorf', 'Nordrhein-Westfalen', 51.2277, 6.7735),
    GermanCity('Erlangen', 'Bayern', 49.5897, 11.0119),
    GermanCity('Erfurt', 'Thüringen', 50.9848, 11.0299),
    GermanCity('Essen', 'Nordrhein-Westfalen', 51.4556, 7.0116),
    GermanCity('Flensburg', 'Schleswig-Holstein', 54.7937, 9.4469),
    GermanCity('Frankfurt am Main', 'Hessen', 50.1109, 8.6821),
    GermanCity('Frankfurt (Oder)', 'Brandenburg', 52.3471, 14.5506),
    GermanCity('Freiburg im Breisgau', 'Baden-Württemberg', 47.9990, 7.8421),
    GermanCity('Fürth', 'Bayern', 49.4771, 10.9887),
    GermanCity('Gelsenkirchen', 'Nordrhein-Westfalen', 51.5177, 7.0857),
    GermanCity('Gießen', 'Hessen', 50.5841, 8.6784),
    GermanCity('Göttingen', 'Niedersachsen', 51.5413, 9.9158),
    GermanCity('Gütersloh', 'Nordrhein-Westfalen', 51.9069, 8.3785),
    GermanCity('Hagen', 'Nordrhein-Westfalen', 51.3671, 7.4633),
    GermanCity('Halle (Saale)', 'Sachsen-Anhalt', 51.4969, 11.9688),
    GermanCity('Hamburg', 'Hamburg', 53.5511, 9.9937),
    GermanCity('Hamm', 'Nordrhein-Westfalen', 51.6739, 7.8159),
    GermanCity('Hannover', 'Niedersachsen', 52.3759, 9.7320),
    GermanCity('Heidelberg', 'Baden-Württemberg', 49.3988, 8.6724),
    GermanCity('Heilbronn', 'Baden-Württemberg', 49.1427, 9.2109),
    GermanCity('Hildesheim', 'Niedersachsen', 52.1508, 9.9511),
    GermanCity('Ingolstadt', 'Bayern', 48.7665, 11.4257),
    GermanCity('Iserlohn', 'Nordrhein-Westfalen', 51.3755, 7.7028),
    GermanCity('Jena', 'Thüringen', 50.9271, 11.5892),
    GermanCity('Kaiserslautern', 'Rheinland-Pfalz', 49.4401, 7.7491),
    GermanCity('Karlsruhe', 'Baden-Württemberg', 49.0069, 8.4037),
    GermanCity('Kassel', 'Hessen', 51.3127, 9.4797),
    GermanCity('Kiel', 'Schleswig-Holstein', 54.3233, 10.1228),
    GermanCity('Koblenz', 'Rheinland-Pfalz', 50.3569, 7.5890),
    GermanCity('Köln', 'Nordrhein-Westfalen', 50.9375, 6.9603),
    GermanCity('Konstanz', 'Baden-Württemberg', 47.6779, 9.1732),
    GermanCity('Krefeld', 'Nordrhein-Westfalen', 51.3388, 6.5853),
    GermanCity('Landshut', 'Bayern', 48.5442, 12.1469),
    GermanCity('Leipzig', 'Sachsen', 51.3397, 12.3731),
    GermanCity('Leverkusen', 'Nordrhein-Westfalen', 51.0459, 7.0192),
    GermanCity('Lübeck', 'Schleswig-Holstein', 53.8655, 10.6866),
    GermanCity('Ludwigshafen am Rhein', 'Rheinland-Pfalz', 49.4774, 8.4452),
    GermanCity('Magdeburg', 'Sachsen-Anhalt', 52.1205, 11.6276),
    GermanCity('Mainz', 'Rheinland-Pfalz', 49.9929, 8.2473),
    GermanCity('Mannheim', 'Baden-Württemberg', 49.4875, 8.4660),
    GermanCity('Marburg', 'Hessen', 50.8071, 8.7700),
    GermanCity('Mönchengladbach', 'Nordrhein-Westfalen', 51.1805, 6.4428),
    GermanCity('Moers', 'Nordrhein-Westfalen', 51.4516, 6.6408),
    GermanCity('Mülheim an der Ruhr', 'Nordrhein-Westfalen', 51.4186, 6.8845),
    GermanCity('München', 'Bayern', 48.1351, 11.5820),
    GermanCity('Münster', 'Nordrhein-Westfalen', 51.9607, 7.6261),
    GermanCity('Neuss', 'Nordrhein-Westfalen', 51.2042, 6.6879),
    GermanCity('Nürnberg', 'Bayern', 49.4521, 11.0767),
    GermanCity('Oberhausen', 'Nordrhein-Westfalen', 51.4963, 6.8638),
    GermanCity('Offenbach am Main', 'Hessen', 50.0956, 8.7761),
    GermanCity('Oldenburg', 'Niedersachsen', 53.1435, 8.2146),
    GermanCity('Osnabrück', 'Niedersachsen', 52.2799, 8.0472),
    GermanCity('Paderborn', 'Nordrhein-Westfalen', 51.7189, 8.7575),
    GermanCity('Passau', 'Bayern', 48.5667, 13.4319),
    GermanCity('Pforzheim', 'Baden-Württemberg', 48.8922, 8.6946),
    GermanCity('Potsdam', 'Brandenburg', 52.3906, 13.0645),
    GermanCity('Recklinghausen', 'Nordrhein-Westfalen', 51.6141, 7.1979),
    GermanCity('Regensburg', 'Bayern', 49.0134, 12.1016),
    GermanCity('Remscheid', 'Nordrhein-Westfalen', 51.1787, 7.1897),
    GermanCity('Reutlingen', 'Baden-Württemberg', 48.4914, 9.2043),
    GermanCity('Rostock', 'Mecklenburg-Vorpommern', 54.0924, 12.0991),
    GermanCity('Saarbrücken', 'Saarland', 49.2402, 6.9969),
    GermanCity('Salzgitter', 'Niedersachsen', 52.1508, 10.3593),
    GermanCity('Schwerin', 'Mecklenburg-Vorpommern', 53.6355, 11.4012),
    GermanCity('Siegen', 'Nordrhein-Westfalen', 50.8748, 8.0243),
    GermanCity('Solingen', 'Nordrhein-Westfalen', 51.1702, 7.0831),
    GermanCity('Stuttgart', 'Baden-Württemberg', 48.7758, 9.1829),
    GermanCity('Trier', 'Rheinland-Pfalz', 49.7499, 6.6371),
    GermanCity('Tübingen', 'Baden-Württemberg', 48.5216, 9.0576),
    GermanCity('Ulm', 'Baden-Württemberg', 48.4011, 9.9876),
    GermanCity('Weimar', 'Thüringen', 50.9795, 11.3235),
    GermanCity('Wiesbaden', 'Hessen', 50.0782, 8.2398),
    GermanCity('Witten', 'Nordrhein-Westfalen', 51.4439, 7.3532),
    GermanCity('Wolfsburg', 'Niedersachsen', 52.4227, 10.7865),
    GermanCity('Wuppertal', 'Nordrhein-Westfalen', 51.2562, 7.1508),
    GermanCity('Würzburg', 'Bayern', 49.7913, 9.9534),
    GermanCity('Zwickau', 'Sachsen', 50.7189, 12.4961),
  ];
}
