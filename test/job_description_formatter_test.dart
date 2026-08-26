import 'package:flutter_test/flutter_test.dart';
import 'package:werkstudent_ai/services/job_description_formatter.dart';

void main() {
  test('converts partner HTML into readable paragraphs and bullets', () {
    const html = '''
      <p>Werde Teil unseres Teams &amp; sammle Erfahrung.</p>
      <h2>Deine Aufgaben</h2>
      <ul><li>Verträge verwalten</li><li>Daten aktualisieren</li></ul>
    ''';

    expect(
      formatJobDescription(html),
      'Werde Teil unseres Teams & sammle Erfahrung.\n'
      '\nDeine Aufgaben\n'
      '• Verträge verwalten\n'
      '• Daten aktualisieren',
    );
  });

  test('decodes numeric entities and removes unsafe blocks', () {
    const html = '<script>alert(1)</script><p>Gehalt: 18 &#8364;</p>';

    expect(formatJobDescription(html), 'Gehalt: 18 €');
  });

  test('keeps an already plain-text description unchanged', () {
    const description = 'Développe des applications Flutter.\nTravail hybride.';

    expect(formatJobDescription(description), description);
  });

  test('normalizes HTML entities in short partner fields', () {
    expect(
      formatExternalText('<strong>People &amp; Culture</strong>'),
      'People & Culture',
    );
  });
}
