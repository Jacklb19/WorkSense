import 'dart:async';

/// Stub de PushNotificationService — Firebase/FCM desactivado.
/// Mantiene la misma interfaz para no romper el resto del código.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final _routeController = StreamController<String>.broadcast();
  Stream<String> get navigationStream => _routeController.stream;

  Future<void> initialize() async {
    // FCM desactivado — no se requiere google-services.json
  }

  Future<void> refreshTokenForCurrentUser() async {}

  Future<void> deleteTokenOnLogout() async {}

  void dispose() {
    _routeController.close();
  }
}
