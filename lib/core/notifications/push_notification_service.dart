import 'dart:async';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nabad/Models/push_notification_payload.dart';
import 'package:nabad/Repositories/notification_repository.dart';
import 'package:nabad/core/Cache/cache_helper.dart';
import 'package:nabad/core/router/app_router.dart';
import 'package:nabad/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pushChannelId = 'support_messages';
const _pushChannelName = 'Support messages';
const _pushDeduplicationKey = 'push_notification_ids';
const _fcmTokenCacheKey = 'fcm_token';

class PushNotificationEnvelope {
  final PushNotificationPayload payload;
  final String? title;
  final String? body;

  const PushNotificationEnvelope({
    required this.payload,
    this.title,
    this.body,
  });
}

abstract class PushMessagingClient {
  Future<bool> initialize();

  Future<bool> requestPermission();

  Future<String?> getToken();

  Future<void> deleteToken();

  Stream<String> get tokenRefresh;

  Stream<PushNotificationEnvelope> get foregroundMessages;

  Stream<PushNotificationEnvelope> get openedMessages;

  Future<PushNotificationEnvelope?> getInitialMessage();
}

class FirebasePushMessagingClient implements PushMessagingClient {
  static bool _backgroundHandlerRegistered = false;

  @override
  Future<bool> initialize() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return false;
    }
    try {
      if (Firebase.apps.isEmpty) {
        final options = AppFirebaseOptions.currentPlatform;
        await Firebase.initializeApp(options: options);
      }
      if (!_backgroundHandlerRegistered) {
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
        _backgroundHandlerRegistered = true;
      }
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: false,
            badge: true,
            sound: false,
          );
      return true;
    } catch (error) {
      debugPrint('Firebase Messaging is unavailable: $error');
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken == null) return null;
    }
    return FirebaseMessaging.instance.getToken();
  }

  @override
  Future<void> deleteToken() => FirebaseMessaging.instance.deleteToken();

  @override
  Stream<String> get tokenRefresh => FirebaseMessaging.instance.onTokenRefresh;

  @override
  Stream<PushNotificationEnvelope> get foregroundMessages =>
      FirebaseMessaging.onMessage.map(_fromRemoteMessage);

  @override
  Stream<PushNotificationEnvelope> get openedMessages =>
      FirebaseMessaging.onMessageOpenedApp.map(_fromRemoteMessage);

  @override
  Future<PushNotificationEnvelope?> getInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    return message == null ? null : _fromRemoteMessage(message);
  }

  static PushNotificationEnvelope _fromRemoteMessage(RemoteMessage message) {
    final data = <String, dynamic>{...message.data};
    data['title'] ??= message.notification?.title;
    data['body'] ??= message.notification?.body;
    return PushNotificationEnvelope(
      payload: PushNotificationPayload.fromMap(data),
      title: message.notification?.title,
      body: message.notification?.body,
    );
  }
}

class PushNotificationService {
  PushNotificationService({
    PushMessagingClient? client,
    FlutterLocalNotificationsPlugin? localNotifications,
    Future<String> Function()? deviceNameProvider,
    FutureOr<void> Function(PushNotificationPayload)? navigationHandler,
    bool enableLocalNotifications = true,
  }) : _client = client ?? FirebasePushMessagingClient(),
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin(),
       _deviceNameProvider = deviceNameProvider,
       _navigationHandler = navigationHandler,
       _enableLocalNotifications = enableLocalNotifications;

  static final PushNotificationService instance = PushNotificationService();

  final PushMessagingClient _client;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final Future<String> Function()? _deviceNameProvider;
  final FutureOr<void> Function(PushNotificationPayload)? _navigationHandler;
  final bool _enableLocalNotifications;
  NotificationRepository? _repository;
  GlobalKey<NavigatorState>? _navigatorKey;
  PushNotificationPayload? _pendingNavigation;
  final Set<String> _handledNavigationKeys = {};
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  FutureOr<void> Function()? onNotificationsChanged;
  bool _firebaseAvailable = false;
  bool _initialized = false;

  bool get isAvailable => _firebaseAvailable;

  Future<void> initialize({
    required NotificationRepository repository,
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    if (_initialized) return;
    _initialized = true;
    _repository = repository;
    _navigatorKey = navigatorKey;
    _firebaseAvailable = await _client.initialize();
    if (!_firebaseAvailable) return;

    if (_enableLocalNotifications) {
      await _initializeLocalNotifications();
    }
    final permissionGranted = await _client.requestPermission();
    if (!permissionGranted) return;

    _subscriptions.add(
      _client.tokenRefresh.listen((token) {
        unawaited(registerForAuthenticatedUser(token: token));
      }),
    );
    _subscriptions.add(
      _client.foregroundMessages.listen((message) {
        unawaited(_handleForegroundMessage(message));
      }),
    );
    _subscriptions.add(
      _client.openedMessages.listen((message) {
        unawaited(_handleNotificationTap(message.payload));
      }),
    );

    final initialRemoteMessage = await _client.getInitialMessage();
    if (initialRemoteMessage != null) {
      _pendingNavigation = initialRemoteMessage.payload;
    }
    if (_enableLocalNotifications) {
      final localLaunch = await _localNotifications
          .getNotificationAppLaunchDetails();
      final localPayload = localLaunch?.notificationResponse?.payload;
      if (localLaunch?.didNotificationLaunchApp == true &&
          localPayload != null &&
          localPayload.isNotEmpty) {
        _pendingNavigation = _decodePayload(localPayload);
      }
    }

    await registerForAuthenticatedUser();
  }

  Future<bool> registerForAuthenticatedUser({String? token}) async {
    if (!_firebaseAvailable || _repository == null) return false;
    if (CacheHelper.getData(key: 'token') == null) return false;
    try {
      final fcmToken = token ?? await _client.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return false;
      final previousToken = CacheHelper.getDataString(key: _fcmTokenCacheKey);
      if (previousToken != null &&
          previousToken.isNotEmpty &&
          previousToken != fcmToken) {
        try {
          await _repository!.unregisterFcmToken(previousToken);
        } catch (_) {
          // A stale token must not prevent registering the refreshed token.
        }
      }
      await _repository!.registerFcmToken(
        token: fcmToken,
        platform: defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
        deviceName: await (_deviceNameProvider?.call() ?? _deviceName()),
      );
      await CacheHelper.saveData(key: _fcmTokenCacheKey, value: fcmToken);
      return true;
    } catch (error) {
      debugPrint('Could not register FCM token: $error');
      return false;
    }
  }

  Future<bool> unregisterCurrentToken() async {
    if (!_firebaseAvailable || _repository == null) return false;
    try {
      final cached = CacheHelper.getDataString(key: _fcmTokenCacheKey);
      final token = cached?.isNotEmpty == true
          ? cached
          : await _client.getToken();
      if (token != null && token.isNotEmpty) {
        await _repository!.unregisterFcmToken(token);
      }
      await _client.deleteToken();
      await CacheHelper.removeData(key: _fcmTokenCacheKey);
      return true;
    } catch (error) {
      debugPrint('Could not unregister FCM token: $error');
      return false;
    }
  }

  Future<void> processPendingNavigation() async {
    final payload = _pendingNavigation;
    if (payload == null) return;
    if (CacheHelper.getData(key: 'token') == null) return;
    final navigator = _navigatorKey?.currentState;
    if (navigator == null && _navigationHandler == null) return;
    _pendingNavigation = null;
    await _openPayload(payload, navigator);
  }

  Future<void> _initializeLocalNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          unawaited(_handleNotificationTap(_decodePayload(payload)));
        }
      },
    );
    const channel = AndroidNotificationChannel(
      _pushChannelId,
      _pushChannelName,
      description: 'Messages and updates from the clinic support team.',
      importance: Importance.max,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _handleForegroundMessage(
    PushNotificationEnvelope message,
  ) async {
    if (!await _claimNotification(message.payload)) return;
    if (!_enableLocalNotifications) {
      await onNotificationsChanged?.call();
      return;
    }
    final isSupport =
        message.payload.type == 'support_ticket_reply' ||
        message.payload.type == 'support_message';
    final title =
        message.title ??
        message.payload.title ??
        (isSupport ? 'رسالة من فريق الدعم' : 'إشعار جديد');
    final body =
        message.body ??
        message.payload.body ??
        (isSupport
            ? 'لديك رسالة جديدة من فريق الدعم الفني'
            : 'لديك إشعار جديد');
    await _localNotifications.show(
      id:
          message.payload.notificationId ??
          message.payload.deduplicationKey.hashCode & 0x7fffffff,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _pushChannelId,
          _pushChannelName,
          channelDescription:
              'Messages and updates from the clinic support team.',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.payload.toMap()),
    );
    await onNotificationsChanged?.call();
  }

  Future<void> _handleNotificationTap(PushNotificationPayload payload) async {
    if (!_handledNavigationKeys.add(payload.deduplicationKey)) return;
    final navigator = _navigatorKey?.currentState;
    if (navigator == null || CacheHelper.getData(key: 'token') == null) {
      _pendingNavigation = payload;
      return;
    }
    await _openPayload(payload, navigator);
  }

  Future<void> _openPayload(
    PushNotificationPayload payload,
    NavigatorState? navigator,
  ) async {
    if (payload.notificationId != null) {
      try {
        await _repository?.markAsRead(payload.notificationId!);
      } catch (_) {
        // The notification center will reconcile read state from the server.
      }
    }
    await onNotificationsChanged?.call();
    if (_navigationHandler != null) {
      await _navigationHandler(payload);
      return;
    }
    if (payload.opensSupportChat) {
      unawaited(
        navigator!.pushNamed(
          AppRoutes.supportChat,
          arguments: payload.ticketId,
        ),
      );
    } else if (payload.opensAppointments) {
      unawaited(navigator!.pushNamed(AppRoutes.appointments));
    }
  }

  Future<bool> _claimNotification(PushNotificationPayload payload) async {
    final preferences = CacheHelper.sharedPreferences;
    return _claimNotificationId(preferences, payload.deduplicationKey);
  }

  Future<String> _deviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    if (defaultTargetPlatform == TargetPlatform.android) {
      final info = await deviceInfo.androidInfo;
      return [
        info.manufacturer,
        info.model,
      ].where((value) => value.trim().isNotEmpty).join(' ');
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final info = await deviceInfo.iosInfo;
      return info.name.isNotEmpty ? info.name : info.utsname.machine;
    }
    return 'unknown';
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  PushNotificationPayload _decodePayload(String raw) {
    try {
      return PushNotificationPayload.fromMap(
        (jsonDecode(raw) as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      return const PushNotificationPayload(type: '');
    }
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: AppFirebaseOptions.currentPlatform);
    }
  } catch (_) {
    return;
  }

  // Notification payloads are displayed by Android/iOS. Only data-only
  // messages need a local notification here.
  if (message.notification != null) return;
  final data = <String, dynamic>{...message.data};
  final payload = PushNotificationPayload.fromMap(data);
  final preferences = await SharedPreferences.getInstance();
  if (!await _claimNotificationId(preferences, payload.deduplicationKey)) {
    return;
  }

  final plugin = FlutterLocalNotificationsPlugin();
  const initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );
  await plugin.initialize(settings: initializationSettings);
  const details = NotificationDetails(
    android: AndroidNotificationDetails(
      _pushChannelId,
      _pushChannelName,
      channelDescription: 'Messages and updates from the clinic support team.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );
  final isSupport =
      payload.type == 'support_ticket_reply' ||
      payload.type == 'support_message';
  await plugin.show(
    id:
        payload.notificationId ??
        payload.deduplicationKey.hashCode & 0x7fffffff,
    title:
        data['title']?.toString() ??
        (isSupport ? 'رسالة من فريق الدعم' : 'إشعار جديد'),
    body:
        data['body']?.toString() ??
        (isSupport
            ? 'لديك رسالة جديدة من فريق الدعم الفني'
            : 'لديك إشعار جديد'),
    notificationDetails: details,
    payload: jsonEncode(payload.toMap()),
  );
}

Future<bool> _claimNotificationId(
  SharedPreferences preferences,
  String id,
) async {
  final ids = preferences.getStringList(_pushDeduplicationKey) ?? <String>[];
  if (ids.contains(id)) return false;
  final updated = <String>[id, ...ids].take(100).toList();
  await preferences.setStringList(_pushDeduplicationKey, updated);
  return true;
}
