import 'package:nabad/Models/doctor_model.dart';
import 'package:nabad/Models/user_model.dart';
import 'package:nabad/core/Api/end_points.dart';

class DoctorDashboardProfile {
  final int userId;
  final int doctorId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String specialization;
  final String? profileImage;

  const DoctorDashboardProfile({
    required this.userId,
    required this.doctorId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.specialization,
    this.profileImage,
  });

  String get fullName {
    final value = '$firstName $lastName'.trim();
    return value.isEmpty ? 'الطبيب' : value;
  }

  factory DoctorDashboardProfile.fromResponses({
    required dynamic userResponse,
    required dynamic doctorsResponse,
    required int cachedUserId,
  }) {
    final userJson = unwrapMap(userResponse, preferredKeys: const ['user']);
    final user = UserModel.fromJson(userJson);
    final resolvedUserId = user.id != 0 ? user.id : cachedUserId;
    final nestedDoctor =
        asStringMap(userJson['doctor']) ??
        asStringMap(userJson['doctor_profile']) ??
        const <String, dynamic>{};

    DoctorModel? matchedDoctor;
    for (final raw in unwrapList(
      doctorsResponse,
      preferredKeys: const ['doctors'],
    )) {
      final map = asStringMap(raw);
      if (map == null) continue;
      final doctor = DoctorModel.fromJson(map);
      if (doctor.userId == resolvedUserId || doctor.user.id == resolvedUserId) {
        matchedDoctor = doctor;
        break;
      }
    }

    return DoctorDashboardProfile(
      userId: resolvedUserId,
      doctorId:
          matchedDoctor?.id ??
          _toInt(nestedDoctor['id'] ?? userJson['doctor_id']),
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      phone: user.phone,
      specialization: matchedDoctor?.specialization?.trim().isNotEmpty == true
          ? matchedDoctor!.specialization!.trim()
          : (nestedDoctor['specialization'] ??
                    userJson['specialization'] ??
                    'طبيب مختص')
                .toString(),
      profileImage:
          matchedDoctor?.profileImage ??
          buildMediaUrl(
            (nestedDoctor['profile_image'] ?? userJson['profile_image'])
                ?.toString(),
          ),
    );
  }
}

class DoctorAppointment {
  final int id;
  final int patientId;
  final String patientName;
  final String? patientImage;
  final String phone;
  final String email;
  final String bloodType;
  final String allergies;
  final String chronicDiseases;
  final String gender;
  final String birthDate;
  final String date;
  final String time;
  final int durationMinutes;
  final String status;
  final String visitType;
  final String notes;
  final Map<String, dynamic> raw;

  const DoctorAppointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    this.patientImage,
    required this.phone,
    required this.email,
    required this.bloodType,
    required this.allergies,
    required this.chronicDiseases,
    required this.gender,
    required this.birthDate,
    required this.date,
    required this.time,
    required this.durationMinutes,
    required this.status,
    required this.visitType,
    required this.notes,
    required this.raw,
  });

  factory DoctorAppointment.fromJson(Map<String, dynamic> json) {
    final patient =
        asStringMap(json['patient']) ??
        asStringMap(json['Patient']) ??
        const <String, dynamic>{};
    final patientUser =
        asStringMap(patient['user']) ?? asStringMap(patient['User']) ?? patient;

    final firstName = _firstNonEmpty([
      patientUser['first_name'],
      patient['first_name'],
      json['patient_first_name'],
    ]);
    final lastName = _firstNonEmpty([
      patientUser['last_name'],
      patient['last_name'],
      json['patient_last_name'],
    ]);
    final explicitName = _firstNonEmpty([
      json['patient_name'],
      patient['name'],
      patientUser['name'],
    ]);
    final combinedName = '$firstName $lastName'.trim();

    return DoctorAppointment(
      id: _toInt(json['id'] ?? json['appointment_id']),
      patientId: _toInt(patient['id'] ?? json['patient_id']),
      patientName: explicitName.isNotEmpty
          ? explicitName
          : (combinedName.isEmpty ? 'مريض' : combinedName),
      patientImage: buildMediaUrl(
        _firstNonEmpty([
          patient['profile_image'],
          patientUser['profile_image'],
          json['patient_image'],
        ]),
      ),
      phone: _firstNonEmpty([
        patientUser['phone'],
        patient['phone'],
        json['patient_phone'],
      ]),
      email: _firstNonEmpty([
        patientUser['email'],
        patient['email'],
        json['patient_email'],
      ]),
      bloodType: _firstNonEmpty([
        patient['blood_type'],
        patientUser['blood_type'],
        json['blood_type'],
      ]),
      allergies: _firstNonEmpty([
        patient['allergies'],
        patientUser['allergies'],
        json['allergies'],
      ]),
      chronicDiseases: _firstNonEmpty([
        patient['diseases'],
        patient['chronic_diseases'],
        patientUser['diseases'],
        json['diseases'],
      ]),
      gender: _firstNonEmpty([patient['gender'], patientUser['gender']]),
      birthDate: _firstNonEmpty([
        patient['birth_date'],
        patientUser['birth_date'],
      ]),
      date: _firstNonEmpty([json['appointment_date'], json['date']]),
      time: _normalizeTime(
        _firstNonEmpty([json['appointment_time'], json['time']]),
      ),
      durationMinutes: _durationToMinutes(
        json['appointment_duration'] ??
            json['Appointment_duration'] ??
            json['duration'],
      ),
      status: _firstNonEmpty([json['status']]).toLowerCase(),
      visitType: _firstNonEmpty([
        json['visit_type'],
        json['appointment_type'],
        json['type'],
        json['reason'],
      ], fallback: 'استشارة طبية'),
      notes: _firstNonEmpty([
        json['notes'],
        json['reason_for_visit'],
        json['description'],
      ]),
      raw: json,
    );
  }

  DateTime? get dateTime {
    if (date.isEmpty) return null;
    final parsedDate = _parseFlexibleDate(date);
    if (parsedDate == null) return null;
    final timeParts = time.split(':');
    final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;
    return DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      hour,
      minute,
    );
  }

  bool get isToday {
    final value = dateTime;
    final now = DateTime.now();
    return value != null &&
        value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

  bool get isFinished =>
      const {'completed', 'cancelled', 'canceled', 'no_show'}.contains(status);

  bool get isWaiting =>
      isToday &&
      const {'pending', 'confirmed', 'waiting', 'checked_in'}.contains(status);
}

class DoctorNotification {
  final int id;
  final String title;
  final String body;
  final String type;
  final DateTime? createdAt;
  final bool isRead;

  const DoctorNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  factory DoctorNotification.fromJson(Map<String, dynamic> json) {
    final data = asStringMap(json['data']) ?? const <String, dynamic>{};
    return DoctorNotification(
      id: _toInt(json['id']),
      title: _firstNonEmpty([
        json['title'],
        data['title'],
        data['subject'],
      ], fallback: 'تنبيه جديد'),
      body: _firstNonEmpty([
        json['message'],
        json['body'],
        data['message'],
        data['body'],
      ]),
      type: _firstNonEmpty([json['type'], data['type']]),
      createdAt: DateTime.tryParse(
        _firstNonEmpty([json['created_at'], data['created_at']]),
      ),
      isRead:
          json['read_at'] != null ||
          json['is_read'] == true ||
          data['is_read'] == true,
    );
  }
}

class DoctorMedicalRecord {
  final int id;
  final int appointmentId;
  final int patientId;
  final String patientName;
  final String diagnosis;
  final String notes;
  final String diseases;
  final String bloodType;
  final int? heartRate;
  final String allergies;
  final String date;
  final bool referredToPharmacist;
  final bool referredToLaboratory;
  final String laboratoryNotes;
  final String laboratoryStatus;

  const DoctorMedicalRecord({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.patientName,
    required this.diagnosis,
    required this.notes,
    required this.diseases,
    required this.bloodType,
    this.heartRate,
    required this.allergies,
    required this.date,
    required this.referredToPharmacist,
    required this.referredToLaboratory,
    required this.laboratoryNotes,
    required this.laboratoryStatus,
  });

  DoctorMedicalRecord copyWith({
    String? diagnosis,
    String? notes,
    String? diseases,
    String? bloodType,
    int? heartRate,
    String? allergies,
    bool? referredToPharmacist,
    bool? referredToLaboratory,
    String? laboratoryNotes,
  }) => DoctorMedicalRecord(
    id: id,
    appointmentId: appointmentId,
    patientId: patientId,
    patientName: patientName,
    diagnosis: diagnosis ?? this.diagnosis,
    notes: notes ?? this.notes,
    diseases: diseases ?? this.diseases,
    bloodType: bloodType ?? this.bloodType,
    heartRate: heartRate ?? this.heartRate,
    allergies: allergies ?? this.allergies,
    date: date,
    referredToPharmacist: referredToPharmacist ?? this.referredToPharmacist,
    referredToLaboratory: referredToLaboratory ?? this.referredToLaboratory,
    laboratoryNotes: laboratoryNotes ?? this.laboratoryNotes,
    laboratoryStatus: laboratoryStatus,
  );

  factory DoctorMedicalRecord.fromJson(Map<String, dynamic> json) {
    final appointment =
        asStringMap(json['appointment']) ?? const <String, dynamic>{};
    final patient =
        asStringMap(json['patient']) ??
        asStringMap(appointment['patient']) ??
        const <String, dynamic>{};
    final user = asStringMap(patient['user']) ?? patient;
    final fullName =
        '${_firstNonEmpty([user['first_name']])} '
                '${_firstNonEmpty([user['last_name']])}'
            .trim();

    return DoctorMedicalRecord(
      id: _toInt(json['record_id'] ?? json['id']),
      appointmentId: _toInt(json['appointment_id'] ?? appointment['id']),
      patientId: _toInt(patient['id'] ?? json['patient_id']),
      patientName: _firstNonEmpty([
        json['patient_name'],
        patient['name'],
        fullName,
      ], fallback: 'مريض'),
      diagnosis: _firstNonEmpty([json['diagnosis']], fallback: 'غير محدد'),
      notes: _firstNonEmpty([json['notes']]),
      diseases: _firstNonEmpty([json['diseases']]),
      bloodType: _firstNonEmpty([json['blood_type']]),
      heartRate: json['heart_rate'] == null ? null : _toInt(json['heart_rate']),
      allergies: _firstNonEmpty([json['allergies']]),
      date: _firstNonEmpty([
        json['created_at'],
        appointment['appointment_date'],
      ]),
      referredToPharmacist:
          json['refer_to_pharmacist'] == true ||
          json['refer_to_pharmacist'] == 1,
      referredToLaboratory:
          json['refer_to_laboratory'] == true ||
          json['refer_to_laboratory'] == 1 ||
          json['laboratory_status'] != null,
      laboratoryNotes: _firstNonEmpty([json['laboratory_notes']]),
      laboratoryStatus: _firstNonEmpty([json['laboratory_status']]),
    );
  }
}

class DoctorMedicine {
  final int id;
  final String name;
  final String strength;
  final String form;

  const DoctorMedicine({
    required this.id,
    required this.name,
    required this.strength,
    required this.form,
  });

  factory DoctorMedicine.fromJson(Map<String, dynamic> json) {
    return DoctorMedicine(
      id: _toInt(json['id'] ?? json['medicine_id'] ?? json['value']),
      name: _firstNonEmpty([
        json['name'],
        json['medicine_name'],
        json['commercial_name'],
        json['label'],
      ], fallback: 'دواء'),
      strength: _firstNonEmpty([json['strength'], json['concentration']]),
      form: _firstNonEmpty([json['form'], json['dosage_form'], json['type']]),
    );
  }
}

class VisitMedicineInput {
  final int medicineId;
  final String name;
  final String dosage;
  final String frequency;
  final String duration;
  final String notes;

  const VisitMedicineInput({
    required this.medicineId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.notes,
  });

  Map<String, dynamic> toApiJson() => {
    if (medicineId > 0) 'medicine_id': medicineId,
    'medicine_name': name.trim(),
    'name': name.trim(),
    'dosage': dosage.trim(),
    'frequency': frequency.trim(),
    'duration': duration.trim(),
    'notes': notes.trim(),
  };

  Map<String, dynamic> toDraftJson() => {
    'medicine_id': medicineId,
    'name': name,
    'dosage': dosage,
    'frequency': frequency,
    'duration': duration,
    'notes': notes,
  };
}

class DoctorPrescription {
  final int id;
  final int medicalRecordId;
  final String patientName;
  final String instructions;
  final String notes;
  final String status;
  final int itemsCount;
  final String date;
  final String expiresAt;
  final List<VisitMedicineInput> items;

  const DoctorPrescription({
    required this.id,
    required this.medicalRecordId,
    required this.patientName,
    required this.instructions,
    required this.notes,
    required this.status,
    required this.itemsCount,
    required this.date,
    required this.expiresAt,
    required this.items,
  });

  factory DoctorPrescription.fromJson(Map<String, dynamic> json) {
    final record =
        asStringMap(json['medical_record']) ?? const <String, dynamic>{};
    final patient =
        asStringMap(json['patient']) ??
        asStringMap(record['patient']) ??
        const <String, dynamic>{};
    final user = asStringMap(patient['user']) ?? patient;
    final fullName =
        '${_firstNonEmpty([user['first_name']])} '
                '${_firstNonEmpty([user['last_name']])}'
            .trim();
    final items = json['items'] is List ? json['items'] as List : const [];

    return DoctorPrescription(
      id: _toInt(json['id']),
      medicalRecordId: _toInt(json['medical_record_id']),
      patientName: _firstNonEmpty([
        json['patient_name'],
        patient['name'],
        fullName,
      ], fallback: 'مريض'),
      instructions: _firstNonEmpty([json['instructions']]),
      notes: _firstNonEmpty([json['notes']]),
      status: _firstNonEmpty([json['status']], fallback: 'active'),
      itemsCount: _toInt(json['items_count']) > 0
          ? _toInt(json['items_count'])
          : items.length,
      date: _firstNonEmpty([json['issued_at'], json['created_at']]),
      expiresAt: _firstNonEmpty([json['expires_at']]),
      items: items.whereType<Map>().map((item) {
        final data = item.cast<String, dynamic>();
        return VisitMedicineInput(
          medicineId: _toInt(data['medicine_id']),
          name: _firstNonEmpty([data['medicine_name'], data['name']]),
          dosage: _firstNonEmpty([data['dosage']]),
          frequency: _firstNonEmpty([data['frequency']]),
          duration: _firstNonEmpty([data['duration']]),
          notes: _firstNonEmpty([data['notes']]),
        );
      }).toList(),
    );
  }
}

Map<String, dynamic> unwrapMap(
  dynamic response, {
  List<String> preferredKeys = const [],
}) {
  final root = asStringMap(response);
  if (root == null) return const {};

  for (final key in preferredKeys) {
    final preferred = asStringMap(root[key]);
    if (preferred != null) return preferred;
  }

  final data = asStringMap(root['data']);
  if (data != null) {
    for (final key in preferredKeys) {
      final preferred = asStringMap(data[key]);
      if (preferred != null) return preferred;
    }
    return data;
  }

  return root;
}

List<dynamic> unwrapList(
  dynamic response, {
  List<String> preferredKeys = const [],
}) {
  if (response is List) return response;
  final root = asStringMap(response);
  if (root == null) return const [];

  for (final key in preferredKeys) {
    final value = root[key];
    if (value is List) return value;
  }

  final data = root['data'];
  if (data is List) return data;
  final dataMap = asStringMap(data);
  if (dataMap != null) {
    for (final key in preferredKeys) {
      final value = dataMap[key];
      if (value is List) return value;
    }
    if (dataMap['data'] is List) return dataMap['data'] as List;
  }

  return const [];
}

Map<String, dynamic>? asStringMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}

String? buildMediaUrl(String? path) {
  final raw = path?.trim();
  if (raw == null || raw.isEmpty) return null;
  final apiUri = Uri.parse(EndPoints.baseUrl);
  final origin = '${apiUri.scheme}://${apiUri.authority}';

  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    final uri = Uri.tryParse(raw);
    if (uri == null) return raw;
    if (!const {'localhost', '127.0.0.1', '0.0.0.0'}.contains(uri.host)) {
      return raw;
    }
    return uri
        .replace(
          scheme: apiUri.scheme,
          host: apiUri.host,
          port: apiUri.hasPort ? apiUri.port : null,
        )
        .toString();
  }

  final normalized = raw.startsWith('/') ? raw.substring(1) : raw;
  return normalized.startsWith('storage/')
      ? '$origin/$normalized'
      : '$origin/storage/$normalized';
}

String _firstNonEmpty(List<dynamic> values, {String fallback = ''}) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }
  return fallback;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int _durationToMinutes(dynamic value) {
  if (value is num) return value.toInt();
  final text = value?.toString() ?? '';
  final direct = int.tryParse(text);
  if (direct != null) return direct;
  final match = RegExp(r'\d+').firstMatch(text);
  return int.tryParse(match?.group(0) ?? '') ?? 15;
}

String _normalizeTime(String value) {
  if (value.isEmpty) return '';
  final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value);
  if (match == null) return value;
  return '${match.group(1)!.padLeft(2, '0')}:${match.group(2)}';
}

DateTime? _parseFlexibleDate(String value) {
  final normalized = value.trim().split('T').first.replaceAll('/', '-');
  final direct = DateTime.tryParse(normalized);
  if (direct != null) return direct;
  final parts = normalized.split('-');
  if (parts.length != 3) return null;
  final first = int.tryParse(parts[0]);
  final second = int.tryParse(parts[1]);
  final third = int.tryParse(parts[2]);
  if (first == null || second == null || third == null) return null;
  if (parts[0].length == 4) return DateTime(first, second, third);
  return DateTime(third, second, first);
}
