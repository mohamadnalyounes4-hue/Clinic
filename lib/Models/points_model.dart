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
