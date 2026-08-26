import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:werkstudent_ai/services/saved_search_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const service = SavedSearchService();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  SavedJobSearch search(String id, String name) => SavedJobSearch(
    id: id,
    name: name,
    query: 'Flutter',
    filter: 'Pour toi',
    sort: 'match',
    minimumSalary: 16,
    flexibleOnly: true,
    sources: const {'Adzuna', 'Bundesagentur für Arbeit'},
    city: 'Köln',
    radiusKm: 25,
    createdAt: DateTime.utc(2026, 8, 9),
  );

  test('saves, reloads and deletes a complete search', () async {
    await service.save(search('one', 'Flutter Köln'));

    final loaded = await service.loadAll();
    expect(loaded, hasLength(1));
    expect(loaded.first.query, 'Flutter');
    expect(loaded.first.sources, contains('Adzuna'));
    expect(loaded.first.radiusKm, 25);

    final deleted = await service.delete('one');
    expect(deleted, isEmpty);
  });

  test('updates an existing search without duplicating it', () async {
    await service.save(search('same', 'Version 1'));
    await service.save(search('same', 'Version 2'));

    final loaded = await service.loadAll();
    expect(loaded, hasLength(1));
    expect(loaded.first.name, 'Version 2');
  });
}
