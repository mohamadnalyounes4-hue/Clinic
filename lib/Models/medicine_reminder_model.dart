class MedicineReminderModel {
  final int id;
  final String medicineName;
  final String dosage;
  final int hour;
  final int minute;
  final bool enabled;

  const MedicineReminderModel({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.hour,
    required this.minute,
    this.enabled = true,
  });

  String get formattedTime {
    final period = hour >= 12 ? 'م' : 'ص';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  MedicineReminderModel copyWith({
    String? medicineName,
    String? dosage,
    int? hour,
    int? minute,
    bool? enabled,
  }) {
    return MedicineReminderModel(
      id: id,
      medicineName: medicineName ?? this.medicineName,
      dosage: dosage ?? this.dosage,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'medicine_name': medicineName,
    'dosage': dosage,
    'hour': hour,
    'minute': minute,
    'enabled': enabled,
  };

  factory MedicineReminderModel.fromJson(Map<String, dynamic> json) {
    return MedicineReminderModel(
      id: _toInt(json['id']),
      medicineName: json['medicine_name']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? '',
      hour: _toInt(json['hour']),
      minute: _toInt(json['minute']),
      enabled: json['enabled'] != false,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
