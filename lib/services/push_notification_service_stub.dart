import '../data/werkly_repository.dart';

/// Non-web fallback -- web push (VAPID + the Push API) has no native-platform
/// equivalent here, so this is a harmless no-op rather than a real
/// implementation. Selected automatically for any non-web build via the
/// conditional export in push_notification_service.dart.
class PushSubscribeResult {
  const PushSubscribeResult({this.error, this.endpoint});

  final String? error;
  final String? endpoint;

  bool get succeeded => error == null && endpoint != null;
}

class PushNotificationService {
  // ignore: avoid_unused_constructor_parameters
  const PushNotificationService(WerklyRepository repository);

  Future<PushSubscribeResult> subscribe() async =>
      const PushSubscribeResult(error: 'unsupported');

  Future<void> unsubscribe() async {}

  Future<bool> isSubscribed() async => false;
}
