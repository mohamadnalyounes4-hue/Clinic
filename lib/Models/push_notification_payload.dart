class PushNotificationPayload {
  final String type;
  final int? ticketId;
  final int? patientId;
  final int? notificationId;
  final int? appointmentId;
  final int? doctorId;
  final String? appointmentDate;
  final String? appointmentTime;
  final String? reminderType;
  final String? title;
  final String? body;

  const PushNotificationPayload({
    required this.type,
    this.ticketId,
    this.patientId,
    this.notificationId,
    this.appointmentId,
    this.doctorId,
    this.appointmentDate,
    this.appointmentTime,
    this.reminderType,
    this.title,
    this.body,
  });

  factory PushNotificationPayload.fromMap(Map<String, dynamic> data) {
    return PushNotificationPayload(
      type: data['type']?.toString() ?? '',
      ticketId: _toInt(data['ticket_id']),
      patientId: _toInt(data['patient_id']),
      notificationId: _toInt(data['notification_id']),
      appointmentId: _toInt(data['appointment_id']),
      doctorId: _toInt(data['doctor_id']),
      appointmentDate: data['appointment_date']?.toString(),
      appointmentTime: data['appointment_time']?.toString(),
      reminderType: data['reminder_type']?.toString(),
      title: data['title']?.toString(),
      body: data['body']?.toString(),
    );
  }

  bool get opensSupportChat =>
      (type == 'support_ticket_reply' || type == 'support_message') &&
      ticketId != null;

  bool get opensAppointments =>
      type.startsWith('appointment_') && appointmentId != null;

  String get deduplicationKey => notificationId != null
      ? 'notification:$notificationId'
      : '$type:${ticketId ?? appointmentId ?? ''}:${reminderType ?? ''}:${body ?? ''}';

  Map<String, dynamic> toMap() => {
    'type': type,
    if (ticketId != null) 'ticket_id': ticketId,
    if (patientId != null) 'patient_id': patientId,
    if (notificationId != null) 'notification_id': notificationId,
    if (appointmentId != null) 'appointment_id': appointmentId,
    if (doctorId != null) 'doctor_id': doctorId,
    if (appointmentDate != null) 'appointment_date': appointmentDate,
    if (appointmentTime != null) 'appointment_time': appointmentTime,
    if (reminderType != null) 'reminder_type': reminderType,
    if (title != null) 'title': title,
    if (body != null) 'body': body,
  };

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
