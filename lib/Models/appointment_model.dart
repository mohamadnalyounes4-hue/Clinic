class AppointmentModel {
  final int id;
  final String appointmentDate;
  final String appointmentTime;
  final String? appointmentDuration;
  String status;
  final double price;
  final double? discountAmount;
  final int? pointsRedeemed;
  final double finalPrice;
  final int? pointsAwarded;
  final String? paymentStatus;
  final String? paymentMethod;
  final bool isWalkIn;
  final int? rating;
  final DateTime? ratedAt;
  final bool canRate;
  final AppointmentDoctorModel doctor;

  AppointmentModel({
    required this.id,
    required this.appointmentDate,
    required this.appointmentTime,
    this.appointmentDuration,
    required this.status,
    required this.price,
    this.discountAmount,
    this.pointsRedeemed,
    required this.finalPrice,
    this.pointsAwarded,
    this.paymentStatus,
    this.paymentMethod,
    required this.isWalkIn,
    this.rating,
    this.ratedAt,
    required this.canRate,
    required this.doctor,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: _toInt(json['id']),
      appointmentDate: (json['appointment_date'] ?? '').toString(),
      appointmentTime: (json['appointment_time'] ?? '').toString(),
      appointmentDuration: json['Appointment_duration']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      price: _toDouble(json['price']),
      discountAmount: _toNullableDouble(json['discount_amount']),
      pointsRedeemed: _toNullableInt(json['points_redeemed']),
      finalPrice: _toDouble(json['final_price'] ?? json['price']),
      pointsAwarded: _toNullableInt(json['points_awarded']),
      paymentStatus: json['payment_status']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      isWalkIn: json['is_walk_in'] == true,
      rating: _toNullableInt(json['rating']),
      ratedAt: _parseNullableDateTime(json['rated_at']),
      canRate: json['can_rate'] == true,
      doctor: AppointmentDoctorModel.fromJson(
        (json['doctor'] as Map?)?.cast<String, dynamic>() ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointment_date': appointmentDate,
      'appointment_time': appointmentTime,
      'Appointment_duration': appointmentDuration,
      'status': status,
      'price': price.toStringAsFixed(2),
      'discount_amount': discountAmount,
      'points_redeemed': pointsRedeemed,
      'final_price': finalPrice.toStringAsFixed(2),
      'points_awarded': pointsAwarded,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'is_walk_in': isWalkIn,
      'rating': rating,
      'rated_at': ratedAt?.toIso8601String(),
      'can_rate': canRate,
      'doctor': doctor.toJson(),
    };
  }

  String get doctorName => doctor.name;
  String get specialty => doctor.specialization;
  String get date => appointmentDate;
  String get time => appointmentTime;
  String get imagePath => doctor.profileImage ?? '';

  DateTime? get dateTime {
    final date = _parseAppointmentDate(appointmentDate);
    if (date == null) return null;

    final timeParts = appointmentTime.split(':');
    final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  bool get isUpcoming {
    final value = dateTime;
    if (value == null) return false;
    return status == 'confirmed' && value.isAfter(DateTime.now());
  }

  bool get isCompleted => status == 'completed';
  bool get isCanceled => status == 'canceled' || status == 'cancelled';
  bool get isNoShow => status == 'no_show';

  /// وقت الموعد عدّى فعليًا (بغض النظر عن حالته بالباك). بنستخدمها بس
  /// عشان نصنّف المواعيد بالواجهة (تاب "المنتهية")، مش كمصدر حقيقة لحالة
  /// الموعد الفعلية — التأكيد الرسمي إنه "completed" لسه بيجي من الباك،
  /// والتقييم (can_rate) لسه بيتفعّل بس لما العيادة تأكد الموعد فعليًا.
  bool get isPastScheduledTime {
    final value = dateTime;
    if (value == null) return false;
    return value.isBefore(DateTime.now());
  }
}

typedef Appointment = AppointmentModel;

class AppointmentDoctorModel {
  final int id;
  final String name;
  final String specialization;
  final double? averageRating;
  final int ratingsCount;
  final String? profileImage;

  const AppointmentDoctorModel({
    required this.id,
    required this.name,
    required this.specialization,
    this.averageRating,
    required this.ratingsCount,
    this.profileImage,
  });

  factory AppointmentDoctorModel.fromJson(Map<String, dynamic> json) {
    return AppointmentDoctorModel(
      id: _toInt(json['id']),
      name: (json['name'] ?? '').toString(),
      specialization: (json['specialization'] ?? '').toString(),
      averageRating: _toNullableDouble(json['average_rating']),
      ratingsCount: _toInt(json['ratings_count']),
      profileImage: json['profile_image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialization': specialization,
      'average_rating': averageRating,
      'ratings_count': ratingsCount,
      'profile_image': profileImage,
    };
  }
}

DateTime? _parseAppointmentDate(String value) {
  if (value.isEmpty) return null;

  final separator = value.contains('-') ? '-' : '/';
  final parts = value.split(separator);
  if (parts.length != 3) return DateTime.tryParse(value);

  final first = int.tryParse(parts[0]);
  final second = int.tryParse(parts[1]);
  final third = int.tryParse(parts[2]);
  if (first == null || second == null || third == null) return null;

  if (parts[0].length == 4) {
    return DateTime(first, second, third);
  }

  return DateTime(third, second, first);
}

DateTime? _parseNullableDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _toNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
