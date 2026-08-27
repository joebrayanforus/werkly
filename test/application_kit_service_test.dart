import 'dart:convert';
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

  test(
    'wraps an unusually long letter onto extra pages instead of clipping it',
    () async {
      // A single fixed-size pw.Page silently drops content that overflows
      // the page instead of throwing, so the only way to catch a
      // regression here is to check the actual page count in the output --
      // this reproduces the length of a messy, unedited AI reply (preamble
      // + notes + address block + the real letter).
      final longLetter = List.generate(
        18,
        (i) =>
            'Paragraph $i: mit großem Interesse bewerbe ich mich auf diese '
            'Stelle und bringe umfangreiche praktische Erfahrung mit, die '
            'genau zu den Anforderungen der Stellenausschreibung passt.',
      ).join('\n\n');

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
          coverLetter: longLetter,
          generatedAt: DateTime.utc(2026, 8, 9),
          language: AppLanguage.de,
        ),
      );

      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      final raw = latin1.decode(bytes, allowInvalid: true);
      final pageObjectCount = RegExp(
        r'/Type\s*/Page(?!s)',
      ).allMatches(raw).length;
      expect(
        pageObjectCount,
        greaterThanOrEqualTo(2),
        reason: 'a letter this long must flow onto a second page, not be cut off',
      );
    },
  );
}
