import 'dart:js_interop';

import '../data/werkly_repository.dart';

// Plain JS glue in web/index.html does the actual Push API work (permission
// request, service worker registration, subscribe/unsubscribe) and returns
// a JSON-friendly object -- far less error-prone than hand-writing full
// typed bindings for the Push API's nullable/ArrayBuffer-heavy surface.
@JS('werklySubscribePush')
external JSPromise<JSAny?> _subscribePushJs();

@JS('werklyUnsubscribePush')
external JSPromise<JSAny?> _unsubscribePushJs();

@JS('werklyPushStatus')
external JSPromise<JSAny?> _pushStatusJs();

class PushSubscribeResult {
  const PushSubscribeResult({this.error, this.endpoint});

  /// null, 'unsupported' (no browser support), or 'denied' (user declined
  /// the permission prompt).
  final String? error;
  final String? endpoint;

  bool get succeeded => error == null && endpoint != null;
}

class PushNotificationService {
  const PushNotificationService(this._repository);

  final WerklyRepository _repository;

  Future<PushSubscribeResult> subscribe() async {
    final raw = await _subscribePushJs().toDart;
    final result = raw?.dartify();
    if (result is! Map) return const PushSubscribeResult(error: 'unsupported');
    final error = result['error'] as String?;
    if (error != null) return PushSubscribeResult(error: error);
    final endpoint = result['endpoint'] as String?;
    final p256dh = result['p256dh'] as String?;
    final auth = result['auth'] as String?;
    if (endpoint == null || p256dh == null || auth == null) {
      return const PushSubscribeResult(error: 'incomplete');
    }
    await _repository.registerPushSubscription(
      endpoint: endpoint,
      p256dh: p256dh,
      auth: auth,
    );
    return PushSubscribeResult(endpoint: endpoint);
  }

  Future<void> unsubscribe() async {
    final raw = await _unsubscribePushJs().toDart;
    final result = raw?.dartify();
    final endpoint = result is Map ? result['endpoint'] as String? : null;
    if (endpoint != null) {
      await _repository.removePushSubscription(endpoint);
    }
  }

  Future<bool> isSubscribed() async {
    final raw = await _pushStatusJs().toDart;
    final result = raw?.dartify();
    return result is Map && result['subscribed'] == true;
  }
}
