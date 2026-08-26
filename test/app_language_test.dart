import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:werkstudent_ai/l10n/app_language.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppLanguageController.language.value = AppLanguage.fr;
  });

  test('provides the core navigation in three languages', () {
    expect(const AppStrings(AppLanguage.fr).get('jobs'), 'Offres');
    expect(const AppStrings(AppLanguage.de).get('jobs'), 'Jobs');
    expect(const AppStrings(AppLanguage.en).get('map'), 'Map');
  });

  test('persists and restores the selected language', () async {
    await AppLanguageController.setLanguage(AppLanguage.de);
    AppLanguageController.language.value = AppLanguage.fr;

    await AppLanguageController.initialize();

    expect(AppLanguageController.language.value, AppLanguage.de);
  });

  test('starts in English until a language is selected', () async {
    AppLanguageController.language.value = AppLanguage.fr;

    await AppLanguageController.initialize();

    expect(AppLanguageController.language.value, AppLanguage.en);
  });

  test('localizes tutorial and dynamic job labels', () {
    expect(
      const AppStrings(AppLanguage.fr).get('tutorialLanguageTitle'),
      'Choisis ta langue',
    );
    expect(
      const AppStrings(AppLanguage.de).get('tutorialMapTitle'),
      'Die Entfernung, die wirklich zählt',
    );
    expect(
      const AppStrings(AppLanguage.en).format('jobsForYou', {'count': 12}),
      '12 jobs for you',
    );
    expect(
      const AppStrings(AppLanguage.de).get('reportAiContent'),
      'Diese Antwort melden',
    );
  });

  test('localizes favorites and assistant controls', () {
    expect(
      const AppStrings(AppLanguage.fr).get('removeFavorite'),
      'Retirer des favoris',
    );
    expect(
      const AppStrings(AppLanguage.de).get('removeFavorite'),
      'Aus Favoriten entfernen',
    );
    expect(
      const AppStrings(AppLanguage.en).get('addFavorite'),
      'Add to favorites',
    );
    expect(
      const AppStrings(AppLanguage.de).get('assistantInterviewPrompt'),
      'Mein Gespräch vorbereiten',
    );
  });

  test('localizes the complete interview header', () {
    expect(
      AppStrings(
        AppLanguage.en,
      ).format('interviewTitleCompany', {'company': 'Example GmbH'}),
      'Interview · Example GmbH',
    );
    expect(
      AppStrings(
        AppLanguage.de,
      ).format('questionProgress', {'current': 2, 'total': 6}),
      'Frage 2/6',
    );
    expect(
      AppStrings(
        AppLanguage.fr,
      ).format('interviewProgressPrivate', {'progress': 50}),
      contains('préparé'),
    );
  });

  test('localizes generated documents and system notifications', () {
    expect(
      const AppStrings(AppLanguage.en).get('pdfCoverLetter'),
      'COVER LETTER',
    );
    expect(
      const AppStrings(AppLanguage.de).get('applicationReminderTitle'),
      'Bewerbungserinnerung',
    );
    expect(
      const AppStrings(AppLanguage.fr).get('moderationPending'),
      'En attente',
    );
  });
}
