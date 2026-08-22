import 'package:nabad/Models/patient_notification_model.dart';

class SupportNotificationModel {
  final int id;
  final String type;
  final String title;
  final String body;
  final int? ticketId;
  final bool isRead;
  final DateTime? createdAt;

  const SupportNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.ticketId,
    required this.isRead,
    required this.createdAt,
  });

  factory SupportNotificationModel.fromPatientNotification(
    PatientNotificationModel notification,
  ) {
    return SupportNotificationModel(
      id: notification.id,
      type: notification.type,
      title: notification.title,
      body: notification.body,
      ticketId: _nullableInt(notification.data['ticket_id']),
      isRead: notification.isRead,
      createdAt: notification.createdAt,
    );
  }

  bool get opensSupportChat =>
      (type == 'support_ticket_reply' || type == 'support_message') &&
      ticketId != null;

  bool get isSupportNotification =>
      type.startsWith('support_') || type == 'support_message';

  static int? _nullableInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
