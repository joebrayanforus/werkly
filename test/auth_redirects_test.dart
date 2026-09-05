import 'package:flutter_test/flutter_test.dart';
import 'package:werkstudent_ai/services/auth_redirects.dart';

void main() {
  test('uses the app deep link for mobile password recovery', () {
    expect(
      werklyPasswordRecoveryRedirect(web: false),
      werklyPasswordRecoveryDeepLink,
    );
  });

  test('uses the current web origin without stale fragments', () {
    final redirect = werklyPasswordRecoveryRedirect(
      web: true,
      currentUri: Uri.parse('http://localhost:57815/jobs?old=1#section'),
    );

    expect(redirect, 'http://localhost:57815/jobs?auth=recovery');
  });

  test(
    'preserves a GitHub Pages-style deployment sub-path for password recovery',
    () {
      final redirect = werklyPasswordRecoveryRedirect(
        web: true,
        currentUri: Uri.parse(
          'https://joebrayanforus.github.io/werkly/?old=1#section',
        ),
      );

      expect(
        redirect,
        'https://joebrayanforus.github.io/werkly/?auth=recovery',
      );
    },
  );

  test('uses the app deep link for mobile Google sign-in', () {
    expect(werklyGoogleOAuthRedirect(web: false), werklyGoogleOAuthDeepLink);
  });

  test(
    'preserves a GitHub Pages-style deployment sub-path for Google sign-in',
    () {
      final redirect = werklyGoogleOAuthRedirect(
        web: true,
        currentUri: Uri.parse('https://joebrayanforus.github.io/werkly/'),
      );

      expect(redirect, 'https://joebrayanforus.github.io/werkly/');
    },
  );
}
