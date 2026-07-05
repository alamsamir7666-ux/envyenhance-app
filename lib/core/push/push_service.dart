import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import '../api/push_repository.dart';
import '../auth/auth_service.dart';

/// Handles the full push notification lifecycle:
///  - Requesting notification permission (required on Android 13+/iOS)
///  - Registering this device's FCM token with our backend so it can be
///    targeted by `sendPushToUser` (see lib/push.ts server-side)
///  - Showing a system notification when a push arrives while the app is
///    in the foreground (FCM only auto-displays notifications when the
///    app is backgrounded/killed — foreground messages need to be shown
///    manually via flutter_local_notifications)
///  - Deep-linking to the relevant screen when a notification is tapped,
///    using the `route` field the server includes in its data payload
///    (see ORDER_STATUS_MESSAGES / sendPreOrderArrivedPush in lib/push.ts)
///
/// Call [initialize] once, after the router exists (main.dart), and call
/// [syncTokenForCurrentUser] whenever sign-in state changes so the token
/// is (re-)registered under the correct user and unregistered on sign-out.
class PushService {
  PushService(this._pushRepository, this._authService, this._router);

  final PushRepository _pushRepository;
  final AuthService _authService;
  final GoRouter _router;

  final _localNotifications = FlutterLocalNotificationsPlugin();
  String? _currentToken;
  bool _initialized = false;

  static const _androidChannel = AndroidNotificationChannel(
    'envyenhance_default',
    'Order & Account Updates',
    description: 'Order status changes, pre-order arrivals, and account notifications.',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);

      await _localNotifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (response) {
          final route = response.payload;
          if (route != null && route.isNotEmpty) {
            _router.push(route);
          }
        },
      );

      // Foreground messages don't auto-display — show them ourselves.
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);

      // Tapped while app was backgrounded (not killed).
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // App was launched by tapping a notification from a killed state.
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // Re-register if FCM rotates the token (happens occasionally).
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        if (_authService.isSignedIn) {
          _pushRepository.registerToken(newToken).catchError((_) {});
        }
      });
    } catch (e) {
      // Push notifications are a nicety, not core functionality — never
      // let setup failure (e.g. Firebase not configured yet, no
      // google-services.json bundled) block app startup.
      debugPrint('[push] Initialization failed (non-fatal): $e');
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data['route'] as String?,
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route != null && route.isNotEmpty) {
      _router.push(route);
    }
  }

  /// Registers (or unregisters) this device's FCM token with the backend
  /// to match the current sign-in state. Safe to call repeatedly — e.g.
  /// from a listener on auth state changes.
  Future<void> syncTokenForCurrentUser() async {
    try {
      if (!_authService.isSignedIn) {
        if (_currentToken != null) {
          await _pushRepository.unregisterToken(_currentToken!).catchError((_) {});
        }
        return;
      }

      final token = _currentToken ?? await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      _currentToken = token;
      await _pushRepository.registerToken(token);
    } catch (e) {
      debugPrint('[push] Token sync failed (non-fatal): $e');
    }
  }
}
