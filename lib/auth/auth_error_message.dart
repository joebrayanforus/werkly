import '../l10n/app_language.dart';

bool authErrorNeedsConfirmation(String message) {
  final normalized = message.toLowerCase();
  return normalized.contains('email not confirmed') ||
      normalized.contains('confirm your email') ||
      normalized.contains('email confirmation');
}

String localizedAuthErrorMessage(String message, AppLanguage language) {
  final normalized = message.toLowerCase();
  final strings = AppStrings(language);

  if (normalized.contains('invalid login credentials') ||
      normalized.contains('invalid credentials')) {
    return strings.get('authInvalidCredentials');
  }
  if (authErrorNeedsConfirmation(message)) {
    return strings.get('authEmailNotConfirmed');
  }
  if (normalized.contains('already registered') ||
      normalized.contains('user already exists')) {
    return strings.get('authUserExists');
  }
  if (normalized.contains('rate limit') ||
      normalized.contains('too many requests')) {
    return strings.get('authRateLimit');
  }
  if (normalized.contains('password should') ||
      normalized.contains('weak password')) {
    return strings.get('authWeakPassword');
  }
  if (normalized.contains('expired') ||
      normalized.contains('invalid otp') ||
      normalized.contains('token has expired')) {
    return strings.get('authExpiredLink');
  }
  if (normalized.contains('error sending confirmation email') ||
      normalized.contains('failed to send confirmation email') ||
      normalized.contains('email could not be sent')) {
    return strings.get('authEmailDeliveryFailed');
  }
  return strings.get('authGenericError');
}
