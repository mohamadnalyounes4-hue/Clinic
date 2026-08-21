import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/states/patient_medical_record_state.dart';
import 'package:nabad/Models/patient_medical_record_model.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';

class PatientMedicalRecordCubit extends Cubit<PatientMedicalRecordState> {
  final ApiConsumer api;

  PatientMedicalRecordCubit({required this.api})
    : super(const PatientMedicalRecordState());

  Future<void> loadMedicalFile() async {
    emit(
      PatientMedicalRecordState(
        status: PatientMedicalRecordStatus.loading,
        records: state.records,
      ),
    );

    try {
      final responses = await Future.wait<dynamic>([
        _safeGet(EndPoints.patientMedicalRecords),
        _safeGet(EndPoints.profilePatient),
        _safeGet(EndPoints.appointments),
        _safeGet(EndPoints.patientPrescriptions),
        _safeGet(EndPoints.prescriptions),
      ]);

      if (responses.take(3).every((response) => response == null)) {
        throw StateError('No medical file source is available');
      }

      final prescriptions = responses
          .where((response) => response != null)
          .expand(extractPatientPrescriptions)
          .map(PatientPrescription.fromJson)
          .toList(growable: false);
      final prescriptionsByRecord = <int, PatientPrescription>{};
      for (final prescription in prescriptions) {
        if (prescription.medicalRecordId == 0) continue;
        prescriptionsByRecord[prescription.medicalRecordId] =
            _richerPrescription(
              prescriptionsByRecord[prescription.medicalRecordId],
              prescription,
            );
      }

      final recordsByVisit = <String, PatientMedicalRecord>{};
      for (final response in responses.take(3)) {
        if (response == null) continue;
        for (final rawRecord in extractPatientMedicalRecords(response)) {
          var record = PatientMedicalRecord.fromJson(rawRecord);
          record = record.copyWith(
            prescription:
                prescriptionsByRecord[record.id] ?? record.prescription,
          );
          final key = _recordKey(record);
          recordsByVisit[key] = _richerRecord(recordsByVisit[key], record);
        }
      }
      final records = recordsByVisit.values.toList();

      records.sort((first, second) {
        final firstDate = DateTime.tryParse(first.date);
        final secondDate = DateTime.tryParse(second.date);
        if (firstDate != null && secondDate != null) {
          return secondDate.compareTo(firstDate);
        }
        return second.id.compareTo(first.id);
      });

      emit(
        PatientMedicalRecordState(
          status: PatientMedicalRecordStatus.success,
          records: records,
        ),
      );
    } catch (_) {
      emit(
        PatientMedicalRecordState(
          status: PatientMedicalRecordStatus.failure,
          records: state.records,
          errorMessage: 'تعذر تحميل الملف الطبي. تحقق من الاتصال وحاول مجددًا.',
        ),
      );
    }
  }

  Future<dynamic> _safeGet(String endpoint) async {
    try {
      return await api.get(endpoint);
    } catch (_) {
      return null;
    }
  }

  String _recordKey(PatientMedicalRecord record) {
    if (record.appointmentId != 0) return 'appointment:${record.appointmentId}';
    if (record.id != 0) return 'record:${record.id}';
    return 'content:${record.date}:${record.diagnosis}';
  }

  PatientMedicalRecord _richerRecord(
    PatientMedicalRecord? current,
    PatientMedicalRecord candidate,
  ) {
    if (current == null) return candidate;
    final richer = _recordScore(candidate) > _recordScore(current)
        ? candidate
        : current;
    final linkedPrescription =
        richer.prescription ?? current.prescription ?? candidate.prescription;
    return richer.copyWith(prescription: linkedPrescription);
  }

  int _recordScore(PatientMedicalRecord record) {
    return [
          record.diagnosis == 'غير محدد' ? '' : record.diagnosis,
          record.bloodType,
          record.allergies,
          record.diseases,
          record.notes,
          record.laboratoryNotes,
          record.date,
          record.doctorSpecialization,
        ].where((value) => value.isNotEmpty).length +
        (record.heartRate == null ? 0 : 1) +
        (record.prescription == null ? 0 : 3);
  }

  PatientPrescription _richerPrescription(
    PatientPrescription? current,
    PatientPrescription candidate,
  ) {
    if (current == null) return candidate;
    final currentScore =
        current.items.length * 3 +
        (current.instructions.isEmpty ? 0 : 1) +
        (current.notes.isEmpty ? 0 : 1);
    final candidateScore =
        candidate.items.length * 3 +
        (candidate.instructions.isEmpty ? 0 : 1) +
        (candidate.notes.isEmpty ? 0 : 1);
    return candidateScore > currentScore ? candidate : current;
  }
}
