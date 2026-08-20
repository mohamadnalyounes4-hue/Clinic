class PatientMedicalRecord {
  final int id;
  final int appointmentId;
  final String diagnosis;
  final String bloodType;
  final String allergies;
  final int? heartRate;
  final String diseases;
  final String notes;
  final bool referredToPharmacist;
  final bool referredToLaboratory;
  final String laboratoryNotes;
  final String date;
  final String doctorName;
  final String doctorSpecialization;
  final PatientPrescription? prescription;

  const PatientMedicalRecord({
    required this.id,
    required this.appointmentId,
    required this.diagnosis,
    required this.bloodType,
    required this.allergies,
    required this.heartRate,
    required this.diseases,
    required this.notes,
    required this.referredToPharmacist,
    required this.referredToLaboratory,
    required this.laboratoryNotes,
    required this.date,
    required this.doctorName,
    required this.doctorSpecialization,
    this.prescription,
  });

  factory PatientMedicalRecord.fromJson(Map<String, dynamic> json) {
    final appointment = _asMap(json['appointment'] ?? json['Appointment']);
    final doctor = _asMap(json['doctor'] ?? json['Doctor']).isNotEmpty
        ? _asMap(json['doctor'] ?? json['Doctor'])
        : _asMap(appointment['doctor'] ?? appointment['Doctor']);
    final doctorUser = _asMap(doctor['user'] ?? doctor['User']).isNotEmpty
        ? _asMap(doctor['user'] ?? doctor['User'])
        : doctor;
    final firstName = _firstText([
      doctorUser['first_name'],
      doctor['first_name'],
    ]);
    final lastName = _firstText([doctorUser['last_name'], doctor['last_name']]);
    final combinedDoctorName = '$firstName $lastName'.trim();
    final embeddedPrescription = _firstMap(
      json['prescription'] ??
          json['Prescription'] ??
          json['prescriptions'] ??
          json['Prescriptions'],
    );

    return PatientMedicalRecord(
      id: _asInt(json['record_id'] ?? json['id'] ?? json['medical_record_id']),
      appointmentId: _asInt(json['appointment_id'] ?? appointment['id']),
      diagnosis: _firstText([
        json['diagnosis'],
        json['diagnose'],
        json['medical_diagnosis'],
      ], fallback: 'غير محدد'),
      bloodType: _firstText([
        json['blood_type'],
        json['bloodType'],
        json['blood_group'],
      ]),
      allergies: _firstText([json['allergies']]),
      heartRate: _nullableInt(json['heart_rate'] ?? json['heartRate']),
      diseases: _firstText([
        json['diseases'],
        json['chronic_diseases'],
        json['chronicDiseases'],
      ]),
      notes: _firstText([json['notes'], json['doctor_notes']]),
      referredToPharmacist: _asBool(
        json['refer_to_pharmacist'] ?? json['referToPharmacist'],
      ),
      referredToLaboratory:
          _asBool(json['refer_to_laboratory'] ?? json['referToLaboratory']) ||
          json['laboratory_status'] != null ||
          _firstText([
            json['laboratory_notes'],
            json['laboratoryNotes'],
          ]).isNotEmpty,
      laboratoryNotes: _firstText([
        json['laboratory_notes'],
        json['laboratoryNotes'],
      ]),
      date: _firstText([
        json['created_at'],
        json['createdAt'],
        json['date'],
        appointment['appointment_date'],
      ]),
      doctorName: _firstText([
        json['doctor_name'],
        doctor['name'],
        combinedDoctorName,
      ], fallback: 'الطبيب المعالج'),
      doctorSpecialization: _firstText([
        doctor['specialization'],
        appointment['doctor_specialization'],
        json['doctor_specialization'],
      ]),
      prescription: embeddedPrescription.isEmpty
          ? null
          : PatientPrescription.fromJson(embeddedPrescription),
    );
  }

  PatientMedicalRecord copyWith({PatientPrescription? prescription}) {
    return PatientMedicalRecord(
      id: id,
      appointmentId: appointmentId,
      diagnosis: diagnosis,
      bloodType: bloodType,
      allergies: allergies,
      heartRate: heartRate,
      diseases: diseases,
      notes: notes,
      referredToPharmacist: referredToPharmacist,
      referredToLaboratory: referredToLaboratory,
      laboratoryNotes: laboratoryNotes,
      date: date,
      doctorName: doctorName,
      doctorSpecialization: doctorSpecialization,
      prescription: prescription ?? this.prescription,
    );
  }
}

class PatientPrescription {
  final int id;
  final int medicalRecordId;
  final String instructions;
  final String notes;
  final String status;
  final String date;
  final List<PatientPrescriptionItem> items;

  const PatientPrescription({
    required this.id,
    required this.medicalRecordId,
    required this.instructions,
    required this.notes,
    required this.status,
    required this.date,
    required this.items,
  });

  factory PatientPrescription.fromJson(Map<String, dynamic> json) {
    final record = _asMap(json['medical_record'] ?? json['medicalRecord']);
    final rawItems = _asList(
      json['items'] ?? json['prescription_items'] ?? json['medicines'],
    );
    return PatientPrescription(
      id: _asInt(json['id'] ?? json['prescription_id']),
      medicalRecordId: _asInt(
        json['medical_record_id'] ?? json['medicalRecordId'] ?? record['id'],
      ),
      instructions: _firstText([json['instructions']]),
      notes: _firstText([json['notes']]),
      status: _firstText([json['status']], fallback: 'active'),
      date: _firstText([json['created_at'], json['date']]),
      items: rawItems
          .map(_asMap)
          .where((item) => item.isNotEmpty)
          .map(PatientPrescriptionItem.fromJson)
          .toList(growable: false),
    );
  }
}

class PatientPrescriptionItem {
  final int medicineId;
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String notes;

  const PatientPrescriptionItem({
    required this.medicineId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.notes,
  });

  factory PatientPrescriptionItem.fromJson(Map<String, dynamic> json) {
    final medicine = _asMap(json['medicine']);
    final pivot = _asMap(json['pivot']);
    return PatientPrescriptionItem(
      medicineId: _asInt(json['medicine_id'] ?? medicine['id']),
      name: _firstText([
        json['medicine_name'],
        json['name'],
        medicine['name'],
        medicine['commercial_name'],
      ], fallback: 'دواء'),
      dosage: _firstText([json['dosage'], pivot['dosage']]),
      frequency: _firstText([json['frequency'], pivot['frequency']]),
      duration: _firstText([json['duration'], pivot['duration']]),
      notes: _firstText([json['notes'], pivot['notes']]),
    );
  }
}

List<dynamic> unwrapPatientMedicalList(
  dynamic response, {
  List<String> preferredKeys = const [],
}) {
  if (response is List) return response;
  final root = _asMap(response);
  if (root.isEmpty) return const [];

  for (final key in preferredKeys) {
    final value = root[key];
    if (value is List) return value;
  }

  final data = root['data'];
  if (data is List) return data;
  final dataMap = _asMap(data);
  for (final key in preferredKeys) {
    final value = dataMap[key];
    if (value is List) return value;
  }
  if (dataMap['data'] is List) return dataMap['data'] as List;
  return const [];
}

/// Finds medical records even when the backend embeds them in a patient
/// profile, an appointment, a paginated response, or returns one record only.
List<Map<String, dynamic>> extractPatientMedicalRecords(dynamic response) {
  final result = <Map<String, dynamic>>[];

  void visit(dynamic value, [String parentKey = '']) {
    if (value is List) {
      for (final item in value) {
        visit(item, parentKey);
      }
      return;
    }
    final map = _asMap(value);
    if (map.isEmpty) return;

    final normalizedParent = parentKey.toLowerCase().replaceAll(
      RegExp(r'[^a-z]'),
      '',
    );
    final isMedicalRecordParent = normalizedParent.contains('medicalrecord');
    final hasMedicalValues = const [
      'diagnosis',
      'diagnose',
      'medical_diagnosis',
      'heart_rate',
      'heartRate',
      'refer_to_laboratory',
      'referToLaboratory',
      'laboratory_notes',
      'laboratoryNotes',
    ].any(map.containsKey);

    if (hasMedicalValues ||
        (isMedicalRecordParent &&
            (map.containsKey('id') || map.containsKey('appointment_id')))) {
      result.add(map);
    }

    for (final entry in map.entries) {
      if (entry.value is Map || entry.value is List) {
        visit(entry.value, entry.key);
      }
    }
  }

  visit(response);
  return result;
}

/// Finds prescriptions in both their dedicated response and inside records.
List<Map<String, dynamic>> extractPatientPrescriptions(dynamic response) {
  final result = <Map<String, dynamic>>[];

  void visit(dynamic value, [String parentKey = '']) {
    if (value is List) {
      for (final item in value) {
        visit(item, parentKey);
      }
      return;
    }
    final map = _asMap(value);
    if (map.isEmpty) return;

    final normalizedParent = parentKey.toLowerCase().replaceAll(
      RegExp(r'[^a-z]'),
      '',
    );
    final isPrescriptionParent = normalizedParent.contains('prescription');
    final hasPrescriptionValues = const [
      'medical_record_id',
      'medicalRecordId',
      'instructions',
      'prescription_items',
    ].any(map.containsKey);
    if ((isPrescriptionParent || hasPrescriptionValues) &&
        (map.containsKey('id') || hasPrescriptionValues)) {
      result.add(map);
    }

    for (final entry in map.entries) {
      if (entry.value is Map || entry.value is List) {
        visit(entry.value, entry.key);
      }
    }
  }

  visit(response);
  return result;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return const <String, dynamic>{};
}

Map<String, dynamic> _firstMap(dynamic value) {
  final direct = _asMap(value);
  if (direct.isNotEmpty) return direct;
  if (value is List && value.isNotEmpty) return _asMap(value.first);
  return const <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) => value is List ? value : const [];

String _firstText(List<dynamic> values, {String fallback = ''}) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }
  return fallback;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return const {'1', 'true', 'yes'}.contains(value?.toString().toLowerCase());
}
