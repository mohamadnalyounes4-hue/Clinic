import 'package:flutter_test/flutter_test.dart';
import 'package:nabad/Cubits/cubits/patient_medical_record_cubit.dart';
import 'package:nabad/Cubits/states/patient_medical_record_state.dart';
import 'package:nabad/Models/patient_medical_record_model.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';

void main() {
  test('parses every value saved by the doctor visit form', () {
    final record = PatientMedicalRecord.fromJson({
      'id': 77,
      'appointment_id': 44,
      'diagnosis': 'التهاب قصبات',
      'blood_type': 'O+',
      'allergies': 'بنسلين',
      'heart_rate': 76,
      'diseases': 'ربو',
      'notes': 'مراجعة بعد أسبوع',
      'refer_to_pharmacist': true,
      'refer_to_laboratory': 1,
      'laboratory_notes': 'CBC',
      'created_at': '2026-08-20T10:00:00.000Z',
      'appointment': {
        'doctor': {
          'specialization': 'صدرية',
          'user': {'first_name': 'سمير', 'last_name': 'المنصوري'},
        },
      },
    });

    expect(record.diagnosis, 'التهاب قصبات');
    expect(record.bloodType, 'O+');
    expect(record.allergies, 'بنسلين');
    expect(record.heartRate, 76);
    expect(record.diseases, 'ربو');
    expect(record.notes, 'مراجعة بعد أسبوع');
    expect(record.referredToPharmacist, isTrue);
    expect(record.referredToLaboratory, isTrue);
    expect(record.laboratoryNotes, 'CBC');
    expect(record.doctorName, 'سمير المنصوري');
    expect(record.doctorSpecialization, 'صدرية');
  });

  test(
    'loads visits and attaches each prescription to its medical record',
    () async {
      final api = _MedicalFileApi();
      final cubit = PatientMedicalRecordCubit(api: api);

      await cubit.loadMedicalFile();

      expect(cubit.state.status, PatientMedicalRecordStatus.success);
      expect(cubit.state.records, hasLength(1));
      final record = cubit.state.records.single;
      expect(record.prescription?.instructions, 'بعد الطعام');
      expect(record.prescription?.items.single.name, 'أموكسيسيلين');
      expect(record.prescription?.items.single.dosage, '500mg');
      expect(api.getPaths, contains(EndPoints.patientMedicalRecords));
      expect(api.getPaths, isNot(contains(EndPoints.medicalRecords)));
      await cubit.close();
    },
  );

  test(
    'falls back to a medical record embedded in the patient profile',
    () async {
      final cubit = PatientMedicalRecordCubit(api: _EmbeddedMedicalFileApi());

      await cubit.loadMedicalFile();

      expect(cubit.state.status, PatientMedicalRecordStatus.success);
      expect(cubit.state.records, hasLength(1));
      expect(cubit.state.records.single.diagnosis, 'صداع نصفي');
      expect(cubit.state.records.single.heartRate, 70);
      expect(
        cubit.state.records.single.prescription?.items.single.name,
        'دواء',
      );
      await cubit.close();
    },
  );
}

class _MedicalFileApi extends ApiConsumer {
  final List<String> getPaths = [];

  @override
  Future<dynamic> get(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async {
    getPaths.add(path);
    if (path == EndPoints.patientMedicalRecords) {
      return {
        'data': {
          'data': [
            {
              'id': 77,
              'diagnosis': 'التهاب قصبات',
              'heart_rate': 76,
              'created_at': '2026-08-20T10:00:00.000Z',
            },
          ],
        },
      };
    }
    if (path == EndPoints.prescriptions) {
      return {
        'data': [
          {
            'id': 91,
            'medical_record_id': 77,
            'instructions': 'بعد الطعام',
            'items': [
              {
                'medicine_id': 9,
                'dosage': '500mg',
                'medicine': {'name': 'أموكسيسيلين'},
              },
            ],
          },
        ],
      };
    }
    return const <String, dynamic>{};
  }

  @override
  Future<dynamic> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async => const <String, dynamic>{};

  @override
  Future<dynamic> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async => const <String, dynamic>{};

  @override
  Future<dynamic> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async => const <String, dynamic>{};
}

class _EmbeddedMedicalFileApi extends ApiConsumer {
  @override
  Future<dynamic> get(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async {
    if (path == EndPoints.patientMedicalRecords) {
      throw Exception('not available');
    }
    if (path == EndPoints.profilePatient) {
      return {
        'data': {
          'id': 5,
          'medicalRecord': {
            'id': 88,
            'appointment_id': 55,
            'diagnosis': 'صداع نصفي',
            'heartRate': '70',
            'prescriptions': [
              {
                'id': 99,
                'items': [
                  {
                    'medicine': {'name': 'دواء'},
                    'pivot': {'dosage': 'حبة واحدة'},
                  },
                ],
              },
            ],
          },
        },
      };
    }
    return const <String, dynamic>{};
  }

  @override
  Future<dynamic> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async => const <String, dynamic>{};

  @override
  Future<dynamic> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async => const <String, dynamic>{};

  @override
  Future<dynamic> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async => const <String, dynamic>{};
}
