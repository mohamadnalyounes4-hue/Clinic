class DoctorEarningsModel {
  final DoctorEarningsSummary summary;
  final List<DoctorEarningsEntry> ledger;

  const DoctorEarningsModel({required this.summary, required this.ledger});

  factory DoctorEarningsModel.fromJson(Map<String, dynamic> json) {
    final data = _map(json['data'] ?? json);
    final rawLedger = data['ledger'];
    return DoctorEarningsModel(
      summary: DoctorEarningsSummary.fromJson(_map(data['summary'])),
      ledger: rawLedger is List
          ? rawLedger
                .whereType<Map>()
                .map((item) => DoctorEarningsEntry.fromJson(_map(item)))
                .toList(growable: false)
          : const [],
    );
  }
}

class DoctorEarningsSummary {
  final int appointments;
  final double gross;
  final double doctorShare;
  final double platformShare;

  const DoctorEarningsSummary({
    required this.appointments,
    required this.gross,
    required this.doctorShare,
    required this.platformShare,
  });

  factory DoctorEarningsSummary.fromJson(Map<String, dynamic> json) {
    return DoctorEarningsSummary(
      appointments: _int(json['appointments']),
      gross: _double(json['gross']),
      doctorShare: _double(json['doctor_share']),
      platformShare: _double(json['platform_share']),
    );
  }
}

class DoctorEarningsEntry {
  final int appointmentId;
  final String date;
  final double gross;
  final double doctorShare;
  final double platformShare;

  const DoctorEarningsEntry({
    required this.appointmentId,
    required this.date,
    required this.gross,
    required this.doctorShare,
    required this.platformShare,
  });

  factory DoctorEarningsEntry.fromJson(Map<String, dynamic> json) {
    return DoctorEarningsEntry(
      appointmentId: _int(json['appointment_id']),
      date: (json['date'] ?? '').toString(),
      gross: _double(json['gross']),
      doctorShare: _double(json['doctor_share']),
      platformShare: _double(json['platform_share']),
    );
  }
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

int _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

double _double(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
