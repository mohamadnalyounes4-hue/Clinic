class DoctorScheduleModel {
  final int id;
  final String day;
  final String startTime;
  final String endTime;

  const DoctorScheduleModel({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  factory DoctorScheduleModel.fromJson(Map<String, dynamic> json) {
    return DoctorScheduleModel(
      id: int.tryParse((json['id'] ?? '').toString()) ?? 0,
      day: (json['day'] ?? '').toString(),
      startTime: (json['start_time'] ?? '').toString(),
      endTime: (json['end_time'] ?? '').toString(),
    );
  }
}
