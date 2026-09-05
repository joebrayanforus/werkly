import 'package:flutter/foundation.dart';

import '../l10n/app_language.dart';

const werklyAuthConfirmedUrl =
    'https://bygqatraidykcxjfjala.supabase.co/functions/v1/auth-confirmed';

String werklyAuthConfirmedUrlFor(AppLanguage language) =>
    '$werklyAuthConfirmedUrl?lang=${language.code}';

const werklyPasswordRecoveryDeepLink = 'de.werkly.app://reset-callback/';
const werklyGoogleOAuthDeepLink = 'de.werkly.app://login-callback/';

String werklyPasswordRecoveryRedirect({bool? web, Uri? currentUri}) {
  if (web ?? kIsWeb) {
    final uri = currentUri ?? Uri.base;
    if (uri.hasAuthority) {
      return Uri(
        scheme: uri.scheme,
        userInfo: uri.userInfo,
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
        path: uri.path.isEmpty ? '/' : uri.path,
        queryParameters: const {'auth': 'recovery'},
      ).toString();
    }
  }
  return werklyPasswordRecoveryDeepLink;
}

String werklyGoogleOAuthRedirect({bool? web, Uri? currentUri}) {
  if (web ?? kIsWeb) {
    final uri = currentUri ?? Uri.base;
    if (uri.hasAuthority) {
      return Uri(
        scheme: uri.scheme,
        userInfo: uri.userInfo,
        host: uri.host,
        port: uri.hasPort ? uri.port : null,
        path: uri.path.isEmpty ? '/' : uri.path,
      ).toString();
    }
  }
  return werklyGoogleOAuthDeepLink;
}
