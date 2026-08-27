import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:werkstudent_ai/l10n/app_language.dart';
import 'package:werkstudent_ai/services/application_kit_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates a two-part application PDF', () async {
    final bytes = await ApplicationKitService.buildPdf(
      ApplicationKitData(
        applicantName: 'Alex Martin',
        email: 'alex@example.com',
        degree: 'Master Informatik',
        university: 'TU München',
        city: 'München',
        summary: 'Flutter developer with practical project experience.',
        profileSkills: const ['Flutter', 'Dart', 'Git'],
        jobTitle: 'Werkstudent Software Engineering',
        company: 'Example GmbH',
        jobLocation: 'München',
        jobTags: const ['Flutter', 'REST API', 'Git'],
        sourceUrl: 'https://example.com/job',
        coverLetter:
            'Sehr geehrte Damen und Herren,\n\nmit großem Interesse bewerbe ich mich.\n\nMit freundlichen Grüßen\nAlex Martin',
        generatedAt: DateTime.utc(2026, 8, 9),
        language: AppLanguage.en,
      ),
    );

    expect(bytes.length, greaterThan(3000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');

    final sample = File('tmp/pdfs/werkly_application_kit_sample.pdf');
    await sample.parent.create(recursive: true);
    await sample.writeAsBytes(bytes, flush: true);
  });

  test(
    'keeps boilerplate job tags out of matched and missing skills',
    () {
      final data = ApplicationKitData(
        applicantName: 'Alex Martin',
        email: 'alex@example.com',
        degree: 'Master Informatik',
        university: 'TU München',
        city: 'München',
        summary: 'Flutter developer with practical project experience.',
        profileSkills: const ['Flutter'],
        jobTitle: 'Werkstudent Erneuerbare Energien',
        company: 'Example GmbH',
        jobLocation: 'München',
        jobTags: const ['Werkstudent', 'IT', 'Erneuerbare Energien', 'Flutter'],
        sourceUrl: 'https://example.com/job',
        coverLetter: 'Dear Hiring Team,\n\nI am pleased to apply.\n\nKind regards,\nAlex Martin',
        generatedAt: DateTime.utc(2026, 8, 9),
        language: AppLanguage.en,
      );

      expect(data.matchedSkills, ['Flutter']);
      expect(data.missingSkills, ['Erneuerbare Energien']);
      expect(data.missingSkills, isNot(contains('Werkstudent')));
      expect(data.missingSkills, isNot(contains('IT')));
    },
  );

  test('generates a single-page PDF for just the letter', () async {
    final bytes = await ApplicationKitService.buildLetterPdf(
      ApplicationKitData(
        applicantName: 'Alex Martin',
        email: 'alex@example.com',
        degree: 'Master Informatik',
        university: 'TU München',
        city: 'München',
        summary: 'Flutter developer with practical project experience.',
        profileSkills: const ['Flutter', 'Dart', 'Git'],
        jobTitle: 'Werkstudent Software Engineering',
        company: 'Example GmbH',
        jobLocation: 'München',
        jobTags: const ['Flutter', 'REST API', 'Git'],
        sourceUrl: 'https://example.com/job',
        coverLetter:
            'Sehr geehrte Damen und Herren,\n\nmit großem Interesse bewerbe ich mich.\n\nMit freundlichen Grüßen\nAlex Martin',
        generatedAt: DateTime.utc(2026, 8, 9),
        language: AppLanguage.de,
      ),
    );

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');

    final sample = File('tmp/pdfs/werkly_letter_only_sample.pdf');
    await sample.parent.create(recursive: true);
    await sample.writeAsBytes(bytes, flush: true);
  });
}
