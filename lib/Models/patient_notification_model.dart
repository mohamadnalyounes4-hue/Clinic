class PatientNotificationModel {
  final int id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? createdAt;

  const PatientNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory PatientNotificationModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return PatientNotificationModel(
      id: _toInt(json['id']),
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? 'إشعار جديد',
      body: json['body']?.toString() ?? '',
      data: rawData is Map
          ? rawData.map((key, value) => MapEntry(key.toString(), value))
          : const {},
      isRead: json['is_read'] == true || json['read_at'] != null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  PatientNotificationModel copyWith({bool? isRead}) {
    return PatientNotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
