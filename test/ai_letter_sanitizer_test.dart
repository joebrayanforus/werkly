import 'package:flutter_test/flutter_test.dart';
import 'package:werkstudent_ai/pages/home_page.dart';

void main() {
  test('strips markdown bold, italics and code spans', () {
    final result = sanitizeAiLetter(
      'Dear **Hiring Team**,\n\n'
      'I bring *strong* skills in `Python` and SQL.\n\n'
      'Kind regards,\nAlex',
    );

    expect(result, isNot(contains('*')));
    expect(result, isNot(contains('`')));
    expect(result, contains('Dear Hiring Team,'));
    expect(result, contains('strong'));
    expect(result, contains('Python'));
  });

  test('removes standalone separator lines and collapses extra blank lines', () {
    final result = sanitizeAiLetter(
      'Dear Hiring Team,\n\n***\n\n\n\nKind regards,\nAlex',
    );

    expect(result, isNot(contains('***')));
    expect(result, isNot(contains('\n\n\n')));
  });

  test('cleans a realistic messy AI reply down to plain letter prose', () {
    const messy =
        'Here is a customized cover letter for the **Working Student** '
        'position at Concular.\n\n'
        '*Note: this letter highlights your Python and SQL experience.*\n\n'
        '***\n\n'
        '**Alex Martin**\n'
        '[Street Address]\n'
        '[Postal Code, City]\n\n'
        'Dear Hiring Team,\n\n'
        'I am writing to express my strong interest.\n\n'
        'Kind regards,\nAlex';

    final result = sanitizeAiLetter(messy);

    expect(result, isNot(contains('**')));
    expect(result, isNot(contains('***')));
    expect(result, contains('Dear Hiring Team,'));
  });
}
