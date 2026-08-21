import 'dart:math' as math;

/// The loyalty contract shared by booking, points, and wallet UI.
///
/// Awarding points and moving money must remain server-side and atomic. The
/// client uses these constants to present the policy and to reject a stale or
/// inconsistent server preview before a discounted booking is submitted.
abstract final class LoyaltyPolicy {
  static const int pointsAwardedPerAppointment = 20;
  static const int pointsRequiredForDiscount = 40;
  static const double discountPercentage = 30;

  static bool canRedeem(int pointsBalance) =>
      pointsBalance >= pointsRequiredForDiscount;

  static double discountAmount(double originalPrice) =>
      _roundMoney(originalPrice * discountPercentage / 100);

  static double finalPrice(double originalPrice) =>
      _roundMoney(math.max(0, originalPrice - discountAmount(originalPrice)));

  static bool moneyEquals(double first, double second) =>
      (first - second).abs() < 0.01;

  static double _roundMoney(double value) =>
      (value * 100).roundToDouble() / 100;
}

class PointsSummaryModel {
  final int pointsBalance;
  final bool loyaltyActive;
  final String redemptionRateLabel; // النص الخام من الباك للعرض لو حبينا

  final int pointsPerUnit;
  final double discountPerUnit;
  final double maxDiscountPercent;

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

    return PointsSummaryModel(
      pointsBalance: _toInt(data['points_balance']),
      loyaltyActive: data['loyalty_active'] == true,
      redemptionRateLabel: rateLabel,
      pointsPerUnit: LoyaltyPolicy.pointsRequiredForDiscount,
      discountPerUnit: LoyaltyPolicy.discountPercentage,
      maxDiscountPercent: LoyaltyPolicy.discountPercentage,
    );
  }

  /// نسبة الخصم (%) مقابل عدد نقاط معيّن، بحد أقصى [maxDiscountPercent].
  double discountPercentFor(int pointsToRedeem) {
    return pointsToRedeem == LoyaltyPolicy.pointsRequiredForDiscount
        ? LoyaltyPolicy.discountPercentage
        : 0;
  }

  /// أقصى عدد نقاط له فايدة فعلية (بعده الخصم بيوصل للحد الأقصى وما بيزيد).
  int get pointsForMaxDiscount {
    return LoyaltyPolicy.pointsRequiredForDiscount;
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

  bool matchesLoyaltyPolicy({required double consultationFee}) {
    return loyaltyActive &&
        patientPointsBalance >= LoyaltyPolicy.pointsRequiredForDiscount &&
        pointsRedeemed == LoyaltyPolicy.pointsRequiredForDiscount &&
        LoyaltyPolicy.moneyEquals(
          discountPercentage,
          LoyaltyPolicy.discountPercentage,
        ) &&
        LoyaltyPolicy.moneyEquals(originalPrice, consultationFee) &&
        LoyaltyPolicy.moneyEquals(
          discountAmount,
          LoyaltyPolicy.discountAmount(consultationFee),
        ) &&
        LoyaltyPolicy.moneyEquals(
          finalPrice,
          LoyaltyPolicy.finalPrice(consultationFee),
        );
  }
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
