import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_language.dart';

class SavedJobSearch {
  const SavedJobSearch({
    required this.id,
    required this.name,
    required this.query,
    required this.filter,
    required this.sort,
    required this.minimumSalary,
    required this.flexibleOnly,
    required this.sources,
    required this.city,
    required this.radiusKm,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String query;
  final String filter;
  final String sort;
  final double minimumSalary;
  final bool flexibleOnly;
  final Set<String> sources;
  final String city;
  final int radiusKm;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'query': query,
    'filter': filter,
    'sort': sort,
    'minimum_salary': minimumSalary,
    'flexible_only': flexibleOnly,
    'sources': sources.toList(),
    'city': city,
    'radius_km': radiusKm,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  factory SavedJobSearch.fromJson(Map<String, dynamic> json) => SavedJobSearch(
    id: json['id']?.toString() ?? '',
    name:
        json['name']?.toString() ??
        AppStrings(
          AppLanguageController.language.value,
        ).get('savedSearchDefaultName'),
    query: json['query']?.toString() ?? '',
    filter: json['filter']?.toString() ?? 'Pour toi',
    sort: json['sort']?.toString() ?? 'match',
    minimumSalary: (json['minimum_salary'] as num?)?.toDouble() ?? 0,
    flexibleOnly: json['flexible_only'] == true,
    sources: (json['sources'] as List? ?? const [])
        .map((value) => value.toString())
        .toSet(),
    city: json['city']?.toString() ?? '',
    radiusKm: (json['radius_km'] as num?)?.round() ?? 25,
    createdAt:
        DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );
}

class SavedSearchService {
  const SavedSearchService();

  static const _storageKey = 'werkly_saved_searches_v1';

  Future<List<SavedJobSearch>> loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_storageKey);
    if (encoded == null || encoded.isEmpty) return <SavedJobSearch>[];
    try {
      final value = jsonDecode(encoded);
      if (value is! List) return <SavedJobSearch>[];
      final items =
          value
              .whereType<Map>()
              .map(
                (item) =>
                    SavedJobSearch.fromJson(Map<String, dynamic>.from(item)),
              )
              .where((item) => item.id.isNotEmpty)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (_) {
      return <SavedJobSearch>[];
    }
  }

  Future<List<SavedJobSearch>> save(SavedJobSearch search) async {
    final items = await loadAll();
    items.removeWhere((item) => item.id == search.id);
    items.insert(0, search);
    if (items.length > 20) items.removeRange(20, items.length);
    await _persist(items);
    return items;
  }

  Future<List<SavedJobSearch>> delete(String id) async {
    final items = await loadAll();
    items.removeWhere((item) => item.id == id);
    await _persist(items);
    return items;
  }

  Future<void> _persist(List<SavedJobSearch> items) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}
