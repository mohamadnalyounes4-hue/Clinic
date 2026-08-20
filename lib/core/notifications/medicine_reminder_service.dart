import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:nabad/Models/medicine_reminder_model.dart';
import 'package:nabad/core/Cache/cache_helper.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class MedicineReminderService {
  MedicineReminderService._();

  static final MedicineReminderService instance = MedicineReminderService._();
  static const _storageKey = 'medicine_reminders';
  static const _channelId = 'medicine_reminders';
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _canScheduleExact = true;

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      // timezone.local remains UTC only on platforms that cannot report a zone.
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _notifications.initialize(settings: settings);
  }

  List<MedicineReminderModel> load() {
    final raw = CacheHelper.getDataString(key: _storageKey);
    if (raw == null || raw.isEmpty) return <MedicineReminderModel>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <MedicineReminderModel>[];
      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                MedicineReminderModel.fromJson(item.cast<String, dynamic>()),
          )
          .where((item) => item.medicineName.isNotEmpty)
          .toList();
    } catch (_) {
      return <MedicineReminderModel>[];
    }
  }

  Future<void> save(List<MedicineReminderModel> reminders) async {
    await CacheHelper.saveData(
      key: _storageKey,
      value: jsonEncode(reminders.map((item) => item.toJson()).toList()),
    );
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final notificationsGranted =
          await android.requestNotificationsPermission() ?? true;
      if (!notificationsGranted) return false;
      _canScheduleExact = await android.requestExactAlarmsPermission() ?? true;
      return true;
    }

    final ios = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;
  }

  Future<void> schedule(MedicineReminderModel reminder) async {
    await cancel(reminder.id);
    if (!reminder.enabled) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      reminder.hour,
      reminder.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id: reminder.id,
      title: 'حان موعد دوائك',
      body: reminder.dosage.isEmpty
          ? 'موعد تناول ${reminder.medicineName}'
          : 'تناول ${reminder.medicineName} — ${reminder.dosage}',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'تذكيرات الأدوية',
          channelDescription: 'تنبيهات يومية لمواعيد تناول الأدوية',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: _canScheduleExact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'medicine_reminder:${reminder.id}',
    );
  }

  Future<void> cancel(int id) => _notifications.cancel(id: id);
}
