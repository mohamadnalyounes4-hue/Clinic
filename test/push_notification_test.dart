import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabad/Models/push_notification_payload.dart';
import 'package:nabad/Repositories/notification_repository.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Cache/cache_helper.dart';
import 'package:nabad/core/notifications/push_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();
  });

  test('notification repository uses the FCM token contract', () async {
    final api = _RecordingApi();
    final repository = NotificationRepository(api: api);

    await repository.registerFcmToken(
      token: 'fcm-1',
      platform: 'android',
      deviceName: 'Pixel',
    );
    expect(api.method, 'POST');
    expect(api.path, 'notifications/fcm-token');
    expect(api.data, {
      'fcm_token': 'fcm-1',
      'platform': 'android',
      'device_name': 'Pixel',
    });

    await repository.unregisterFcmToken('fcm-1');
    expect(api.method, 'DELETE');
    expect(api.path, 'notifications/fcm-token');
    expect(api.data, {'fcm_token': 'fcm-1'});
  });

  test(
    'registers, refreshes, and removes the authenticated FCM token',
    () async {
      await CacheHelper.saveData(key: 'token', value: 'patient-token');
      final client = _FakeMessagingClient(token: 'fcm-initial');
      final repository = _FakeNotificationRepository();
      final service = PushNotificationService(
        client: client,
        enableLocalNotifications: false,
        deviceNameProvider: () async => 'Test device',
      );

      await service.initialize(
        repository: repository,
        navigatorKey: GlobalKey<NavigatorState>(),
      );
      expect(repository.registeredTokens, ['fcm-initial']);
      expect(repository.lastDeviceName, 'Test device');

      client.tokenRefreshController.add('fcm-refreshed');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(repository.registeredTokens, ['fcm-initial', 'fcm-refreshed']);
      expect(repository.unregisteredTokens, ['fcm-initial']);

      await service.unregisterCurrentToken();
      expect(repository.unregisteredTokens, ['fcm-initial', 'fcm-refreshed']);
      expect(client.deleted, isTrue);
      expect(CacheHelper.getDataString(key: 'fcm_token'), isNull);
      await client.close();
      await service.dispose();
    },
  );

  test(
    'does not register an FCM token without an authenticated user',
    () async {
      final client = _FakeMessagingClient(token: 'fcm-token');
      final repository = _FakeNotificationRepository();
      final service = PushNotificationService(
        client: client,
        enableLocalNotifications: false,
        deviceNameProvider: () async => 'Test device',
      );

      await service.initialize(
        repository: repository,
        navigatorKey: GlobalKey<NavigatorState>(),
      );
      expect(repository.registeredTokens, isEmpty);
      await client.close();
      await service.dispose();
    },
  );

  test('deduplicates foreground notifications by notification_id', () async {
    await CacheHelper.saveData(key: 'token', value: 'patient-token');
    final client = _FakeMessagingClient(token: 'fcm-token');
    final repository = _FakeNotificationRepository();
    final service = PushNotificationService(
      client: client,
      enableLocalNotifications: false,
      deviceNameProvider: () async => 'Test device',
    );
    var refreshes = 0;
    service.onNotificationsChanged = () => refreshes++;
    await service.initialize(
      repository: repository,
      navigatorKey: GlobalKey<NavigatorState>(),
    );
    const message = PushNotificationEnvelope(
      payload: PushNotificationPayload(
        type: 'support_ticket_reply',
        ticketId: 17,
        notificationId: 99,
      ),
    );

    client.foregroundController.add(message);
    client.foregroundController.add(message);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(refreshes, 1);
    await client.close();
    await service.dispose();
  });

  test('appointment reminder payload keeps its navigation data', () {
    final payload = PushNotificationPayload.fromMap({
      'type': 'appointment_reminder',
      'appointment_id': '15',
      'doctor_id': 5,
      'appointment_date': '2026-08-25',
      'appointment_time': '09:00',
      'reminder_type': 'automatic_48h',
      'notification_id': 99,
    });

    expect(payload.opensAppointments, isTrue);
    expect(payload.appointmentId, 15);
    expect(payload.doctorId, 5);
    expect(payload.appointmentDate, '2026-08-25');
    expect(payload.appointmentTime, '09:00');
    expect(payload.reminderType, 'automatic_48h');
    expect(payload.toMap()['appointment_id'], 15);
  });

  test(
    'terminated notification opens its support conversation and is read',
    () async {
      await CacheHelper.saveData(key: 'token', value: 'patient-token');
      PushNotificationPayload? openedPayload;
      final client = _FakeMessagingClient(
        token: 'fcm-token',
        initialMessage: const PushNotificationEnvelope(
          payload: PushNotificationPayload(
            type: 'support_ticket_reply',
            ticketId: 17,
            patientId: 45,
            notificationId: 789,
          ),
        ),
      );
      final repository = _FakeNotificationRepository();
      final service = PushNotificationService(
        client: client,
        enableLocalNotifications: false,
        deviceNameProvider: () async => 'Test device',
        navigationHandler: (payload) => openedPayload = payload,
      );
      await service.initialize(
        repository: repository,
        navigatorKey: GlobalKey<NavigatorState>(),
      );
      await service.processPendingNavigation();

      expect(openedPayload?.ticketId, 17);
      expect(repository.readIds, [789]);
      await client.close();
      await service.dispose();
    },
  );
}

class _FakeMessagingClient implements PushMessagingClient {
  _FakeMessagingClient({required this.token, this.initialMessage});

  final String? token;
  final PushNotificationEnvelope? initialMessage;
  bool deleted = false;
  final tokenRefreshController = StreamController<String>.broadcast(sync: true);
  final foregroundController =
      StreamController<PushNotificationEnvelope>.broadcast(sync: true);
  final openedController = StreamController<PushNotificationEnvelope>.broadcast(
    sync: true,
  );

  @override
  Future<bool> initialize() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> deleteToken() async => deleted = true;

  @override
  Stream<String> get tokenRefresh => tokenRefreshController.stream;

  @override
  Stream<PushNotificationEnvelope> get foregroundMessages =>
      foregroundController.stream;

  @override
  Stream<PushNotificationEnvelope> get openedMessages =>
      openedController.stream;

  @override
  Future<PushNotificationEnvelope?> getInitialMessage() async => initialMessage;

  Future<void> close() async {
    await tokenRefreshController.close();
    await foregroundController.close();
    await openedController.close();
  }
}

class _FakeNotificationRepository extends NotificationRepository {
  _FakeNotificationRepository() : super(api: _RecordingApi());

  final List<String> registeredTokens = [];
  final List<String> unregisteredTokens = [];
  final List<int> readIds = [];
  String? lastDeviceName;

  @override
  Future<void> registerFcmToken({
    required String token,
    required String platform,
    required String deviceName,
  }) async {
    registeredTokens.add(token);
    lastDeviceName = deviceName;
  }

  @override
  Future<void> unregisterFcmToken(String token) async {
    unregisteredTokens.add(token);
  }

  @override
  Future<void> markAsRead(int id) async => readIds.add(id);
}

class _RecordingApi implements ApiConsumer {
  String? method;
  String? path;
  Object? data;

  @override
  Future<dynamic> get(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async => <String, dynamic>{};

  @override
  Future<dynamic> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async {
    method = 'POST';
    this.path = path;
    this.data = data;
    return <String, dynamic>{};
  }

  @override
  Future<dynamic> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async => <String, dynamic>{};

  @override
  Future<dynamic> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async {
    method = 'DELETE';
    this.path = path;
    this.data = data;
    return <String, dynamic>{};
  }
}
