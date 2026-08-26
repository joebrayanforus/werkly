import 'package:flutter_test/flutter_test.dart';
import 'package:werkstudent_ai/services/german_city_service.dart';

void main() {
  test('suggests Köln with or without the umlaut', () {
    expect(GermanCityService.search('kö').first.name, 'Köln');
    expect(GermanCityService.search('kol').first.name, 'Köln');
  });

  test('suggests cities from partial names', () {
    expect(GermanCityService.search('mun').first.name, 'München');
    expect(GermanCityService.search('sieg').first.name, 'Siegen');
  });

  test('maps a coarse position to the nearest known city', () {
    final result = GermanCityService.nearest(50.875, 8.024);

    expect(result.city.name, 'Siegen');
    expect(result.distanceKm, lessThan(1));
  });
}
