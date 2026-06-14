class Appointment {
  final String doctorName;
  final String specialty;
  final String date;
  final String time;
  final String imagePath; // ✅ جديد
  String status; // ✅ أصبح غير final حتى يتغير عند الإلغاء

  Appointment({
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
    required this.imagePath, // ✅ جديد
    this.status = 'pending',
  });
}
