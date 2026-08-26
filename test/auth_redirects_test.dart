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

    expect(redirect, 'http://localhost:57815/?auth=recovery');
  });
}
