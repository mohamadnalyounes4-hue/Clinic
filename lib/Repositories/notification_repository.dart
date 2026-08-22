import 'package:nabad/Models/notification_model.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';

class NotificationRepository {
  final ApiConsumer api;

  const NotificationRepository({required this.api});

  Future<void> registerFcmToken({
    required String token,
    required String platform,
    required String deviceName,
  }) async {
    await api.post(
      EndPoints.notificationFcmToken,
      data: {
        'fcm_token': token,
        'platform': platform,
        'device_name': deviceName,
      },
    );
  }

  Future<void> unregisterFcmToken(String token) async {
    await api.delete(
      EndPoints.notificationFcmToken,
      data: {'fcm_token': token},
    );
  }

  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int perPage = 15,
  }) async {
    final response = await api.get(
      EndPoints.notifications,
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final raw = response['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => NotificationModel.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await api.get(EndPoints.unreadNotificationsCount);
    final value = response['count'];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> markAsRead(int id) => api.post(EndPoints.readNotification(id));

  Future<void> markAllAsRead() => api.post(EndPoints.readAllNotifications);
}
