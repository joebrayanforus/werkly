import 'package:flutter_test/flutter_test.dart';
import 'package:werkstudent_ai/auth/auth_error_message.dart';
import 'package:werkstudent_ai/l10n/app_language.dart';

void main() {
  test('maps Supabase authentication errors to the selected language', () {
    expect(
      localizedAuthErrorMessage('Invalid login credentials', AppLanguage.fr),
      'Adresse e-mail ou mot de passe incorrect.',
    );
    expect(
      localizedAuthErrorMessage('Email not confirmed', AppLanguage.de),
      'Bestätige zuerst deine E-Mail-Adresse.',
    );
    expect(
      localizedAuthErrorMessage('User already registered', AppLanguage.en),
      'An account already exists for this email address.',
    );
    expect(
      localizedAuthErrorMessage(
        'Error sending confirmation email',
        AppLanguage.en,
      ),
      'The confirmation email cannot be sent right now. Try again later or contact Werkly support.',
    );
  });

  test('does not leak an unknown provider message into the interface', () {
    const providerMessage = 'Undocumented provider-only failure';

    expect(
      localizedAuthErrorMessage(providerMessage, AppLanguage.en),
      'The operation could not be completed. Try again in a moment.',
    );
  });
}
