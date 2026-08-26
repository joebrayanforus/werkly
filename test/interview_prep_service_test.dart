import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:werkstudent_ai/l10n/app_language.dart';
import 'package:werkstudent_ai/services/interview_prep_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const service = InterviewPrepService();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('builds six questions tailored to the job and profile', () {
    final questions = service.buildQuestions(
      language: AppLanguage.en,
      jobTitle: 'Werkstudent Flutter',
      company: 'Mobility GmbH',
      jobSkills: const ['Flutter', 'Git'],
      matchedSkills: const ['Flutter'],
      degree: 'Master Informatik',
      summary: 'Développeur mobile étudiant.',
    );

    expect(questions, hasLength(6));
    expect(questions[1].question, contains('Mobility GmbH'));
    expect(questions[2].question, contains('Flutter'));
    expect(questions.first.question, 'Introduce yourself in 60 seconds.');
    expect(questions.every((item) => item.guidance.isNotEmpty), isTrue);
  });

  test('builds every interview question in the selected language', () {
    List<InterviewQuestion> questions(AppLanguage language) =>
        service.buildQuestions(
          language: language,
          jobTitle: 'Werkstudent Flutter',
          company: 'Mobility GmbH',
          jobSkills: const ['Flutter', 'Git'],
          matchedSkills: const ['Flutter'],
          degree: '',
          summary: '',
        );

    final french = questions(AppLanguage.fr);
    final german = questions(AppLanguage.de);
    final english = questions(AppLanguage.en);

    expect(french, hasLength(6));
    expect(german, hasLength(6));
    expect(english, hasLength(6));
    expect(french.first.question, startsWith('Présente-toi'));
    expect(german.first.question, startsWith('Stell dich'));
    expect(english.first.question, startsWith('Introduce yourself'));
    expect(
      english
          .expand((item) => [item.question, item.purpose, item.guidance])
          .any((text) => text.contains('Pourquoi')),
      isFalse,
    );
    expect(german[1].question, contains('Mobility GmbH'));
  });

  test('persists written answers and rehearsed questions', () async {
    await service.save(
      jobId: 42,
      answers: const {'pitch': 'Je suis étudiant en informatique.'},
      rehearsedQuestionIds: const {'pitch'},
    );

    final session = await service.load(42);

    expect(session.answers['pitch'], contains('étudiant'));
    expect(session.rehearsedQuestionIds, contains('pitch'));
  });

  test('rewards concrete, result-oriented answers', () {
    final vague = service.answerQuality('J’ai travaillé sur un projet.');
    final concrete = service.answerQuality(
      'J’ai développé une application avec une équipe de quatre personnes. '
      'J’ai organisé les tâches, livré le module Flutter et réduit le temps '
      'de chargement de 35 %. Grâce au feedback, j’ai appris à mesurer les '
      'performances avant et après chaque changement.',
    );

    expect(concrete, greaterThan(vague));
    expect(concrete, greaterThanOrEqualTo(70));
  });

  test('rewards concrete English answers', () {
    final vague = service.answerQuality('I worked on a project.');
    final concrete = service.answerQuality(
      'I developed an application with a team of four people. I organized '
      'the tasks, delivered the Flutter module and reduced loading time by '
      '35%. Through feedback, I learned to measure performance before and '
      'after every improvement.',
    );

    expect(concrete, greaterThan(vague));
    expect(concrete, greaterThanOrEqualTo(70));
  });
}
