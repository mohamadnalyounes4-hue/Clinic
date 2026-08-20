import 'package:nabad/Models/patient_medical_record_model.dart';

enum PatientMedicalRecordStatus { initial, loading, success, failure }

class PatientMedicalRecordState {
  final PatientMedicalRecordStatus status;
  final List<PatientMedicalRecord> records;
  final String? errorMessage;

  const PatientMedicalRecordState({
    this.status = PatientMedicalRecordStatus.initial,
    this.records = const [],
    this.errorMessage,
  });

  PatientMedicalRecord? get latestRecord =>
      records.isEmpty ? null : records.first;

  List<PatientMedicalRecord> get laboratoryRecords =>
      records.where((record) => record.referredToLaboratory).toList();
}
