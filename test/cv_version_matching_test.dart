import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:werkstudent_ai/data/werkly_repository.dart';
import 'package:werkstudent_ai/pages/home_page.dart';

void main() {
  Job job({
    required int id,
    required String title,
    required String description,
    required List<String> tags,
  }) => Job(
    id: id,
    title: title,
    company: 'Entreprise $id',
    location: 'Berlin',
    match: 80,
    commute: '20 min',
    salary: '18 €/h',
    source: 'Test',
    sourceUrl: 'https://example.com/$id',
    latitude: 52.52,
    longitude: 13.405,
    color: Colors.green,
    tags: tags,
    description: description,
    posted: 'Récemment',
  );

  CvVersionData version({
    required String label,
    required String category,
    List<String> skills = const [],
    DateTime? updatedAt,
  }) => CvVersionData(
    id: label,
    label: label,
    category: category,
    university: '',
    degree: '',
    city: '',
    professionalSummary: '',
    skills: skills,
    updatedAt: updatedAt,
  );

  test('returns null when there are no saved versions', () {
    final target = job(
      id: 1,
      title: 'Software Developer Flutter',
      description: 'We build software with Flutter.',
      tags: const ['Flutter', 'Werkstudent'],
    );

    expect(bestCvVersionForJob(target, const []), isNull);
  });

  test('category keyword hit beats a higher raw skill count', () {
    final target = job(
      id: 2,
      title: 'Software Developer Flutter',
      description: 'We build software with Flutter.',
      tags: const ['Flutter', 'Werkstudent'],
    );
    final business = version(
      label: 'Business',
      category: 'Business & Finance',
      skills: const ['Flutter', 'Excel'],
    );
    final software = version(
      label: 'Software',
      category: 'Informatique',
      skills: const [],
    );

    final best = bestCvVersionForJob(target, [business, software]);

    expect(best?.label, 'Software');
  });

  test('ties on score are broken by most recently updated', () {
    final target = job(
      id: 3,
      title: 'Software Developer',
      description: 'We build software.',
      tags: const ['Werkstudent'],
    );
    final older = version(
      label: 'Older',
      category: 'Informatique',
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    final newer = version(
      label: 'Newer',
      category: 'Informatique',
      updatedAt: DateTime.utc(2026, 6, 1),
    );

    final best = bestCvVersionForJob(target, [older, newer]);

    expect(best?.label, 'Newer');
  });

  test('generic-tag-only overlap with no category hit returns null', () {
    final target = job(
      id: 4,
      title: 'Werkstudent Praktikum',
      description: 'Allgemeine Aufgaben im Team.',
      tags: const ['Werkstudent'],
    );
    final unrelated = version(
      label: 'Unrelated',
      category: 'Marketing & Design',
      skills: const ['Werkstudent'],
    );

    expect(bestCvVersionForJob(target, [unrelated]), isNull);
  });
}
