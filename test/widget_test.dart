import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:werkstudent_ai/auth/auth_page.dart';

void main() {
  testWidgets('shows the Werkly authentication experience', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthPage()));

    expect(find.text('werkly'), findsOneWidget);
    expect(find.text('Welcome back!'), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
  });
}
