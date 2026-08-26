import 'package:flutter_test/flutter_test.dart';
import 'package:werkstudent_ai/data/werkly_repository.dart';
import 'package:werkstudent_ai/l10n/app_language.dart';
import 'package:werkstudent_ai/services/compatibility_service.dart';

void main() {
  const now = '2026-08-09T12:00:00Z';

  UserProfileData profile({
    List<String> skills = const ['Flutter', 'Dart', 'Git'],
    bool remote = true,
    List<String> fields = const [],
    String weeklyHours = '16–20 h',
    String germanLevel = 'Non précisé',
    Map<String, dynamic> cvAnalysis = const {},
  }) => UserProfileData.guest().copyWith(
    degree: 'Master Informatik',
    professionalSummary: 'Mobile Developer Flutter und Dart',
    skills: skills,
    city: 'Berlin',
    preferences: {
      'remote': remote,
      'fields': fields,
      'weekly_hours': weeklyHours,
      'german_level': germanLevel,
    },
    cvAnalysis: cvAnalysis,
    cvAnalysisStatus: cvAnalysis.isEmpty ? 'not_started' : 'complete',
  );

  CompatibilityBreakdown calculate({
    required UserProfileData user,
    List<String> tags = const ['Flutter', 'Dart', 'REST API'],
    bool remote = true,
    DateTime? postedAt,
    String title = 'Werkstudent Mobile Developer',
    String description =
        'Entwicklung einer Flutter App mit Dart und REST APIs.',
    double? hourlyMin,
    double minimumDesiredSalary = 0,
    double? distanceKm,
    int? searchRadiusKm,
    AppLanguage language = AppLanguage.fr,
  }) => calculateJobCompatibility(
    profile: user,
    jobTags: tags,
    jobTitle: title,
    jobDescription: description,
    jobLocation: 'Berlin',
    remote: remote,
    hourlyMin: hourlyMin,
    minimumDesiredSalary: minimumDesiredSalary,
    distanceKm: distanceKm,
    searchRadiusKm: searchRadiusKm,
    postedAt: postedAt ?? DateTime.parse('2026-08-08T12:00:00Z'),
    now: DateTime.parse(now),
    language: language,
  );

  test('does not invent a default score when the profile is empty', () {
    final result = calculate(user: UserProfileData.guest().copyWith(city: ''));

    expect(result.scored, isFalse);
    expect(result.overall, 0);
  });

  test('localizes compatibility explanations in the selected language', () {
    final english = calculate(
      user: profile(),
      language: AppLanguage.en,
      remote: true,
    );
    final germanEmpty = calculate(
      user: UserProfileData.guest().copyWith(city: ''),
      language: AppLanguage.de,
    );

    expect(english.reasons.join(' '), isNot(contains('offre')));
    expect(english.reasons.join(' '), contains('skill'));
    expect(germanEmpty.cautions.single, contains('Lebenslauf'));
  });

  test('rewards evidenced skills and exposes matched requirements', () {
    final strong = calculate(user: profile());
    final weak = calculate(user: profile(skills: const ['Excel']));

    expect(strong.scored, isTrue);
    expect(strong.overall, greaterThan(weak.overall));
    expect(strong.matchedSkills, containsAll(['Flutter', 'Dart']));
    expect(strong.missingSkills, contains('REST API'));
  });

  test('uses work preferences and location instead of a fixed bar', () {
    final remoteFit = calculate(user: profile(remote: true), remote: true);
    final onsiteMismatch = calculate(
      user: profile(remote: true),
      remote: false,
    );

    expect(
      remoteFit.workConditions,
      greaterThan(onsiteMismatch.workConditions),
    );
  });

  test('fresh offers receive a higher freshness score', () {
    final fresh = calculate(
      user: profile(),
      postedAt: DateTime.parse('2026-08-08T12:00:00Z'),
    );
    final old = calculate(
      user: profile(),
      postedAt: DateTime.parse('2026-05-01T12:00:00Z'),
    );

    expect(fresh.freshness, greaterThan(old.freshness));
    expect(fresh.overall, greaterThan(old.overall));
  });

  test('uses onboarding domains to personalize mission relevance', () {
    final targeted = calculate(user: profile(fields: const ['Informatique']));
    final unrelated = calculate(
      user: profile(fields: const ['Marketing & Design']),
    );

    expect(targeted.relevance, greaterThan(unrelated.relevance));
    expect(targeted.overall, greaterThan(unrelated.overall));
  });

  test('treats all domains as a neutral preference', () {
    final withoutField = calculate(user: profile());
    final allFields = calculate(user: profile(fields: const ['Tous domaines']));

    expect(allFields.relevance, withoutField.relevance);
    expect(allFields.overall, withoutField.overall);
  });

  test('uses the German level extracted from preferences', () {
    final matching = calculate(
      user: profile(germanLevel: 'B2'),
      description: 'Flutter Entwicklung. Deutsch B2 ist erforderlich.',
    );
    final insufficient = calculate(
      user: profile(germanLevel: 'A2'),
      description: 'Flutter Entwicklung. Deutsch B2 ist erforderlich.',
    );

    expect(matching.evaluates('language'), isTrue);
    expect(matching.language, 100);
    expect(insufficient.language, lessThan(matching.language));
    expect(matching.overall, greaterThan(insufficient.overall));
  });

  test(
    'includes salary and distance only when both sides provide evidence',
    () {
      final compatible = calculate(
        user: profile(),
        hourlyMin: 18,
        minimumDesiredSalary: 17,
        distanceKm: 12,
        searchRadiusKm: 25,
      );
      final mismatch = calculate(
        user: profile(),
        hourlyMin: 14,
        minimumDesiredSalary: 18,
        distanceKm: 70,
        searchRadiusKm: 25,
        remote: false,
      );

      expect(compatible.compensation, 100);
      expect(compatible.distance, 100);
      expect(mismatch.compensation, 20);
      expect(mismatch.distance, 15);
      expect(compatible.overall, greaterThan(mismatch.overall));
    },
  );

  test('uses structured CV skills as evidence', () {
    final result = calculate(
      user: profile(
        skills: const [],
        cvAnalysis: const {
          'skills': [
            {'name': 'Flutter', 'level': 'Avancé', 'evidence': 'Projet'},
          ],
        },
      ),
    );

    expect(result.matchedSkills, contains('Flutter'));
    expect(result.confidence, greaterThan(50));
  });

  test('does not score generic occupation tags as technical skills', () {
    final result = calculate(
      user: profile(),
      tags: const ['Informatiker/in'],
      description: 'Unterstützung unseres Teams im Tagesgeschäft.',
    );

    expect(result.evaluates('skills'), isFalse);
    expect(result.cautions, isNotEmpty);
  });

  test('ranks a technical role above an unrelated customer-service role', () {
    final user =
        profile(
          skills: const [
            'Python',
            'Java',
            'TypeScript',
            'SQL',
            'Docker',
            'Git',
          ],
        ).copyWith(
          professionalSummary:
              'Student sucht Softwareentwicklung, Data Engineering und Machine Learning.',
        );
    final technical = calculate(
      user: user,
      title: 'Werkstudent Software & Data Engineering',
      tags: const ['Software', 'Python', 'SQL'],
      description:
          'Entwicklung einer Datenplattform mit Python, SQL und Docker.',
    );
    final unrelated = calculate(
      user: user,
      title: 'Werkstudent Kundenservice und Vertrieb',
      tags: const ['Customer Service', 'Sales'],
      description:
          'Schriftlicher Kundenservice und Bearbeitung von Vertragsanfragen.',
    );

    expect(technical.relevance, greaterThan(unrelated.relevance + 45));
    expect(technical.overall, greaterThan(unrelated.overall));
  });

  test('flags boilerplate job tags so callers do not present them as skills', () {
    expect(isGenericJobTag('Werkstudent'), isTrue);
    expect(isGenericJobTag('werkstudent'), isTrue);
    expect(isGenericJobTag('IT'), isTrue);
    expect(isGenericJobTag('Erneuerbare Energien'), isFalse);
    expect(isGenericJobTag('Flutter'), isFalse);
  });
}
