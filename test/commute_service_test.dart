import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:werkstudent_ai/services/commute_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('reads a real route duration and caches the result', () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests += 1;
      expect(request.url.path, contains('/route/v1/driving/'));
      expect(request.url.queryParameters['overview'], 'false');
      return http.Response(
        '{"code":"Ok","routes":[{"duration":1620,"distance":18400}]}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = CommuteService(
      client: client,
      endpoint: Uri.parse('https://routing.example'),
    );

    final first = await service.estimate(
      fromLatitude: 50.8748,
      fromLongitude: 8.0243,
      toLatitude: 50.9413,
      toLongitude: 6.9583,
    );
    final cached = await service.estimate(
      fromLatitude: 50.8748,
      fromLongitude: 8.0243,
      toLatitude: 50.9413,
      toLongitude: 6.9583,
    );

    expect(first, isNotNull);
    expect(first!.durationMinutes, 27);
    expect(first.distanceKm, closeTo(18.4, .01));
    expect(first.routeUrl.host, 'www.openstreetmap.org');
    expect(cached?.durationMinutes, 27);
    expect(requests, 1);
    service.close();
  });

  test('returns null when the routing provider has no route', () async {
    final service = CommuteService(
      client: MockClient((_) async => http.Response('{"code":"NoRoute"}', 200)),
      endpoint: Uri.parse('https://routing.example'),
    );

    final result = await service.estimate(
      fromLatitude: 50,
      fromLongitude: 8,
      toLatitude: 51,
      toLongitude: 9,
      force: true,
    );

    expect(result, isNull);
    service.close();
  });
}
