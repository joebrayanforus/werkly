import 'dart:io';

import 'package:werkstudent_ai/l10n/app_language.dart';
import 'package:werkstudent_ai/services/application_kit_service.dart';

Future<void> main() async {
  final output = File('tmp/pdfs/werkly_application_kit_sample.pdf');
  await output.parent.create(recursive: true);
  final bytes = await ApplicationKitService.buildPdf(
    ApplicationKitData(
      applicantName: 'Alex Martin',
      email: 'alex.martin@example.com',
      phone: '+49 151 23456789',
      address: 'Musterstraße 12, 80331 München',
      degree: 'Master Informatik',
      university: 'Technische Universität München',
      city: 'München',
      summary:
          'Étudiant en informatique spécialisé dans le développement mobile, avec une expérience pratique sur des applications Flutter connectées à des API REST.',
      profileSkills: const ['Flutter', 'Dart', 'Git', 'SQL', 'Figma'],
      jobTitle: 'Werkstudent Software Engineering',
      company: 'Example Mobility GmbH',
      jobLocation: 'München - Hybrid',
      jobTags: const ['Flutter', 'REST API', 'Git', 'Deutsch'],
      sourceUrl: 'https://example.com/jobs/werkstudent-flutter',
      coverLetter: '''Sehr geehrte Damen und Herren,

mit großem Interesse bewerbe ich mich als Werkstudent Software Engineering bei Example Mobility GmbH. Aktuell studiere ich Master Informatik an der Technischen Universität München.

Besonders ansprechend finde ich die Möglichkeit, meine Kenntnisse in Flutter und Git gezielt einzusetzen und gleichzeitig von Ihrem Team zu lernen. Ich arbeite strukturiert, zuverlässig und gerne im Team.

Gerne überzeuge ich Sie in einem persönlichen Gespräch von meiner Motivation. Ich freue mich auf Ihre Rückmeldung.

Mit freundlichen Grüßen
Alex Martin''',
      generatedAt: DateTime(2026, 8, 9),
      language: AppLanguage.de,
    ),
  );
  await output.writeAsBytes(bytes, flush: true);
  stdout.writeln(output.absolute.path);
}
