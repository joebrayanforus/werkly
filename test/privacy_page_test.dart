import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:werkstudent_ai/l10n/app_language.dart';
import 'package:werkstudent_ai/pages/privacy_page.dart';

void main() {
  testWidgets('shows controller, data use and deletion information', (
    tester,
  ) async {
    AppLanguageController.language.value = AppLanguage.en;

    await tester.pumpWidget(const MaterialApp(home: PrivacyPage()));

    expect(find.text('Privacy policy'), findsNWidgets(2));
    expect(find.textContaining('Tchinda Oumbe Joe Brayan'), findsOneWidget);
    expect(find.textContaining('Data we process'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Retention and deletion'),
      500,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Retention and deletion'), findsOneWidget);
  });
}
