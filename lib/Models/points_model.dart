class PointsSummaryModel {
  final int pointsBalance;
  final bool loyaltyActive;
  final String redemptionRateLabel; // النص الخام من الباك للعرض لو حبينا

  // ── القيم المستخرجة من النص عشان نحسب الخصم بدون ما نفترض أرقام ثابتة ──
  final int pointsPerUnit; // كل كام نقطة = وحدة خصم (افتراضي 100)
  final double discountPerUnit; // % الخصم لكل وحدة (افتراضي 10%)
  final double maxDiscountPercent; // أقصى نسبة خصم (افتراضي 50%)

  const PointsSummaryModel({
    required this.pointsBalance,
    required this.loyaltyActive,
    required this.redemptionRateLabel,
    required this.pointsPerUnit,
    required this.discountPerUnit,
    required this.maxDiscountPercent,
  });

  factory PointsSummaryModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? json) as Map<String, dynamic>;
    final settings = (data['settings'] as Map?)?.cast<String, dynamic>() ?? {};
    final rateLabel = (settings['redemption_rate'] ?? '').toString();

    // القيم الافتراضية المتفق عليها حاليًا: كل 100 نقطة = 10% خصم، حد أقصى 50%.
    // بنحاول نستخرجها من النص الراجع من الباك عشان لو اتغيّر الإعداد هناك
    // الواجهة تتحدث لوحدها من غير تعديل كود.
    int pointsPerUnit = 100;
    double discountPerUnit = 10.0;
    double maxDiscountPercent = 50.0;

    final match = RegExp(
      r'(\d+)\s*points?\s*=\s*([\d.]+)\s*%.*?max\s*([\d.]+)\s*%',
      caseSensitive: false,
    ).firstMatch(rateLabel);

    if (match != null) {
      pointsPerUnit = int.tryParse(match.group(1) ?? '') ?? pointsPerUnit;
      discountPerUnit =
          double.tryParse(match.group(2) ?? '') ?? discountPerUnit;
      maxDiscountPercent =
          double.tryParse(match.group(3) ?? '') ?? maxDiscountPercent;
    }

    return PointsSummaryModel(
      pointsBalance: _toInt(data['points_balance']),
      loyaltyActive: data['loyalty_active'] == true,
      redemptionRateLabel: rateLabel,
      pointsPerUnit: pointsPerUnit <= 0 ? 100 : pointsPerUnit,
      discountPerUnit: discountPerUnit,
      maxDiscountPercent: maxDiscountPercent,
    );
  }

  /// نسبة الخصم (%) مقابل عدد نقاط معيّن، بحد أقصى [maxDiscountPercent].
  double discountPercentFor(int pointsToRedeem) {
    if (pointsToRedeem <= 0 || pointsPerUnit <= 0) return 0;
    final raw = (pointsToRedeem / pointsPerUnit) * discountPerUnit;
    return raw > maxDiscountPercent ? maxDiscountPercent : raw;
  }

  /// أقصى عدد نقاط له فايدة فعلية (بعده الخصم بيوصل للحد الأقصى وما بيزيد).
  int get pointsForMaxDiscount {
    if (discountPerUnit <= 0) return 0;
    return ((maxDiscountPercent / discountPerUnit) * pointsPerUnit).ceil();
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

class PointTransactionModel {
  final int id;
  final String type;
  final int points;
  final int balanceAfter;
  final String? description;
  final String createdAt;
  final int? appointmentId;
  final String? appointmentDate;
  final String? appointmentTime;

  const PointTransactionModel({
    required this.id,
    required this.type,
    required this.points,
    required this.balanceAfter,
    this.description,
    required this.createdAt,
    this.appointmentId,
    this.appointmentDate,
    this.appointmentTime,
  });

  bool get isCredit => points >= 0;

  factory PointTransactionModel.fromJson(Map<String, dynamic> json) {
    final appointment =
        (json['appointment'] as Map?)?.cast<String, dynamic>() ?? {};
    return PointTransactionModel(
      id: _toInt(json['id']),
      type: json['type']?.toString() ?? '',
      points: _toInt(json['points']),
      balanceAfter: _toInt(json['balance_after']),
      description: _nullableText(json['description']),
      createdAt: json['created_at']?.toString() ?? '',
      appointmentId: appointment.isEmpty ? null : _toInt(appointment['id']),
      appointmentDate: _nullableText(appointment['appointment_date']),
      appointmentTime: _nullableText(appointment['appointment_time']),
    );
  }

  static String? _nullableText(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class PointsRedemptionPreviewModel {
  final bool loyaltyActive;
  final int patientPointsBalance;
  final double originalPrice;
  final int pointsRedeemed;
  final double discountPercentage;
  final double discountAmount;
  final double finalPrice;

  const PointsRedemptionPreviewModel({
    required this.loyaltyActive,
    required this.patientPointsBalance,
    required this.originalPrice,
    required this.pointsRedeemed,
    required this.discountPercentage,
    required this.discountAmount,
    required this.finalPrice,
  });

  factory PointsRedemptionPreviewModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map?)?.cast<String, dynamic>() ?? json;
    return PointsRedemptionPreviewModel(
      loyaltyActive: data['loyalty_active'] == true,
      patientPointsBalance: _toInt(data['patient_points_balance']),
      originalPrice: _toDouble(data['original_price']),
      pointsRedeemed: _toInt(data['points_redeemed']),
      discountPercentage: _toDouble(data['discount_percentage']),
      discountAmount: _toDouble(data['discount_amount']),
      finalPrice: _toDouble(data['final_price']),
    );
  }
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
