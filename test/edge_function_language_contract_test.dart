import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AI assistant Edge Function accepts and enforces the app language', () {
    final source = File(
      'supabase/functions/ai-assistant/index.ts',
    ).readAsStringSync();

    expect(source, contains("language?: 'fr' | 'de' | 'en'"));
    expect(source, contains('Reply exclusively in English'));
    expect(source, contains('Antworte ausschließlich auf Deutsch'));
    expect(source, contains('Réponds exclusivement en français'));
    expect(source, contains('Anonymized professional context'));
  });
}
