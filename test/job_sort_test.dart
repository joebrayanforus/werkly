import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:werkstudent_ai/pages/home_page.dart';

void main() {
  Job job({
    required int id,
    required int match,
    required DateTime? postedAt,
    required double? hourlyMin,
  }) => Job(
    id: id,
    title: 'Werkstudent $id',
    company: 'Entreprise $id',
    location: 'Berlin',
    match: match,
    commute: '20 min',
    salary: hourlyMin == null ? 'Non précisé' : '$hourlyMin €/h',
    source: 'Test',
    sourceUrl: 'https://example.com/$id',
    latitude: 52.52,
    longitude: 13.405,
    color: Colors.green,
    tags: const ['Flutter'],
    description: 'Description',
    posted: 'Récemment',
    postedAt: postedAt,
    hourlyMin: hourlyMin,
  );

  final jobs = [
    job(id: 1, match: 72, postedAt: DateTime.utc(2026, 8, 5), hourlyMin: 18),
    job(id: 2, match: 94, postedAt: DateTime.utc(2026, 8, 4), hourlyMin: null),
    job(id: 3, match: 81, postedAt: DateTime.utc(2026, 8, 6), hourlyMin: 16),
  ];

  test('sorts jobs by compatibility', () {
    final sorted = sortJobsForDisplay(jobs, JobSortOption.match);

    expect(sorted.map((job) => job.id), [2, 3, 1]);
  });

  test('embeds job details only inside the wide Jobs view', () {
    expect(usesEmbeddedJobDetails(pageIndex: 1, viewportWidth: 1360), isTrue);
    expect(usesEmbeddedJobDetails(pageIndex: 0, viewportWidth: 1360), isFalse);
    expect(usesEmbeddedJobDetails(pageIndex: 2, viewportWidth: 1360), isFalse);
    // At this width the Jobs page no longer has room for the embedded detail
    // column, so the click must open the job in a sheet instead.
    expect(usesEmbeddedJobDetails(pageIndex: 1, viewportWidth: 1296), isFalse);
    expect(usesEmbeddedJobDetails(pageIndex: 1, viewportWidth: 900), isFalse);
  });

  test('sorts jobs by freshness', () {
    final sorted = sortJobsForDisplay(jobs, JobSortOption.newest);

    expect(sorted.map((job) => job.id), [3, 1, 2]);
  });

  test('sorts jobs by salary and keeps unknown salaries last', () {
    final sorted = sortJobsForDisplay(jobs, JobSortOption.salary);

    expect(sorted.map((job) => job.id), [1, 3, 2]);
  });

  test('separates matching skills from skills to reinforce', () {
    final target = Job(
      id: 4,
      title: 'Werkstudent Mobile',
      company: 'Test',
      location: 'Berlin',
      match: 80,
      commute: '20 min',
      salary: '18 €/h',
      source: 'Test',
      sourceUrl: 'https://example.com/4',
      latitude: 52.52,
      longitude: 13.405,
      color: Colors.green,
      tags: const ['Flutter', 'REST API', 'Git'],
      description: 'Description',
      posted: 'Récemment',
    );

    expect(matchedJobSkills(target, ['Flutter/Dart', 'Git']), [
      'Flutter',
      'Git',
    ]);
    expect(missingJobSkills(target, ['Flutter/Dart', 'Git']), ['REST API']);
  });
}
