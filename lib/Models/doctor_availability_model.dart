class DoctorAvailableDateModel {
  final DateTime date;
  final bool isAvailable;
  final int availableSlots;
  final String? bookingBlockReason;

  const DoctorAvailableDateModel({
    required this.date,
    required this.isAvailable,
    required this.availableSlots,
    this.bookingBlockReason,
  });

  factory DoctorAvailableDateModel.fromJson(Map<String, dynamic> json) {
    return DoctorAvailableDateModel(
      date: DateTime.parse(json['date'].toString()),
      isAvailable: json['is_available'] == true || json['is_available'] == 1,
      availableSlots: _toInt(json['available_slots']),
      bookingBlockReason: json['booking_block_reason']?.toString(),
    );
  }
}

class DoctorAvailabilitySlotModel {
  final String time;
  final String endTime;
  final bool available;
  final String? reason;

  const DoctorAvailabilitySlotModel({
    required this.time,
    required this.endTime,
    required this.available,
    this.reason,
  });

  factory DoctorAvailabilitySlotModel.fromJson(Map<String, dynamic> json) {
    return DoctorAvailabilitySlotModel(
      time: json['time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      available: json['available'] == true || json['available'] == 1,
      reason: json['reason']?.toString(),
    );
  }
}

class DoctorDayAvailabilityModel {
  final DateTime date;
  final bool isWorkingDay;
  final int durationMinutes;
  final List<DoctorAvailabilitySlotModel> slots;
  final String? bookingBlockReason;

  const DoctorDayAvailabilityModel({
    required this.date,
    required this.isWorkingDay,
    required this.durationMinutes,
    required this.slots,
    this.bookingBlockReason,
  });

  factory DoctorDayAvailabilityModel.fromJson(Map<String, dynamic> json) {
    final slots = json['slots'] is List ? json['slots'] as List : const [];
    return DoctorDayAvailabilityModel(
      date: DateTime.parse(json['date'].toString()),
      isWorkingDay:
          json['is_working_day'] == true || json['is_working_day'] == 1,
      durationMinutes: _toInt(json['duration_minutes']),
      slots: slots
          .whereType<Map>()
          .map(
            (item) => DoctorAvailabilitySlotModel.fromJson(
              item.cast<String, dynamic>(),
            ),
          )
          .toList(),
      bookingBlockReason: json['booking_block_reason']?.toString(),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
