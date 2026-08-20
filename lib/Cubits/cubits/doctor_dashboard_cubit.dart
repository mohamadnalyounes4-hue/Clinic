import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/states/doctor_dashboard_state.dart';
import 'package:nabad/Models/doctor_dashboard_model.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';
import 'package:nabad/core/Cache/cache_helper.dart';
import 'package:nabad/core/Error/exceptions.dart';

class DoctorDashboardCubit extends Cubit<DoctorDashboardState> {
  final ApiConsumer api;
  bool _liveRefreshLoading = false;

  DoctorDashboardCubit({required this.api})
    : super(const DoctorDashboardState());

  Future<void> loadDashboard({bool showLoader = true}) async {
    if (showLoader) {
      emit(
        state.copyWith(
          status: DoctorDashboardStatus.loading,
          clearError: true,
          clearNotice: true,
        ),
      );
    }

    try {
      final userResponse = await api.get(EndPoints.currentUser);
      dynamic doctorsResponse = const <String, dynamic>{};
      try {
        doctorsResponse = await api.get(EndPoints.allDoctors);
      } catch (_) {
        // /user may already include the doctor relation. Keep the account
        // usable if the shared doctors directory is temporarily unavailable.
      }
      final cachedUserId =
          (CacheHelper.getData(key: ApiKey.id) as num?)?.toInt() ?? 0;
      final profile = DoctorDashboardProfile.fromResponses(
        userResponse: userResponse,
        doctorsResponse: doctorsResponse,
        cachedUserId: cachedUserId,
      );

      final warnings = <String>[];
      final sectionResponses = await Future.wait<dynamic>([
        _loadDoctorAppointments(profile),
        _safeRequest(
          () => api.get(
            EndPoints.notifications,
            queryParameters: {'per_page': 50, 'unread_only': false},
          ),
          'التنبيهات',
          warnings,
        ),
        _safeRequest(
          () => api.get(EndPoints.unreadNotificationsCount),
          'عدد التنبيهات',
          warnings,
        ),
        _safeRequest(
          () => api.get(EndPoints.doctorMedicalRecords),
          'السجلات',
          warnings,
        ),
        _safeRequest(
          () => api.get(EndPoints.prescriptions),
          'الوصفات',
          warnings,
        ),
        _safeRequest(
          () => api.get(EndPoints.medicinesList),
          'الأدوية',
          warnings,
        ),
      ]);

      final appointmentsResult = sectionResponses[0] as _AppointmentsLoadResult;
      final appointments = appointmentsResult.appointments;

      final notifications =
          unwrapList(
                sectionResponses[1],
                preferredKeys: const ['notifications'],
              )
              .map(asStringMap)
              .whereType<Map<String, dynamic>>()
              .map(DoctorNotification.fromJson)
              .toList();

      final unreadMap = unwrapMap(sectionResponses[2]);
      final unreadCount = _toInt(
        unreadMap['count'] ??
            unreadMap['unread_count'] ??
            notifications.where((item) => !item.isRead).length,
      );

      final records =
          unwrapList(
                sectionResponses[3],
                preferredKeys: const ['medical_records', 'records'],
              )
              .map(asStringMap)
              .whereType<Map<String, dynamic>>()
              .map(DoctorMedicalRecord.fromJson)
              .toList();

      final prescriptions =
          unwrapList(
                sectionResponses[4],
                preferredKeys: const ['prescriptions'],
              )
              .map(asStringMap)
              .whereType<Map<String, dynamic>>()
              .map(DoctorPrescription.fromJson)
              .toList();

      var medicines =
          unwrapList(
                sectionResponses[5],
                preferredKeys: const ['medicines', 'options'],
              )
              .map(asStringMap)
              .whereType<Map<String, dynamic>>()
              .map(DoctorMedicine.fromJson)
              .where((item) => item.id != 0)
              .toList();
      if (medicines.isEmpty) {
        try {
          final response = await api.get(
            EndPoints.medicines,
            queryParameters: {'per_page': 100},
          );
          medicines = unwrapList(response, preferredKeys: const ['medicines'])
              .map(asStringMap)
              .whereType<Map<String, dynamic>>()
              .map(DoctorMedicine.fromJson)
              .where((item) => item.id != 0)
              .toList();
        } catch (_) {
          // The visit screen remains usable without prescribing medicines.
        }
      }

      emit(
        DoctorDashboardState(
          status: DoctorDashboardStatus.success,
          profile: profile,
          appointments: appointments,
          notifications: notifications,
          medicalRecords: records,
          prescriptions: prescriptions,
          medicines: medicines,
          unreadCount: unreadCount,
          appointmentsError: appointmentsResult.errorMessage,
          notice: warnings.isEmpty
              ? null
              : 'تعذر تحديث: ${warnings.toSet().join('، ')}',
        ),
      );
    } on ServerExceptions catch (error) {
      emit(
        state.copyWith(
          status: DoctorDashboardStatus.failure,
          errorMessage: error.errModel.errorMessage,
          clearNotice: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: DoctorDashboardStatus.failure,
          errorMessage: 'تعذر تحميل لوحة الطبيب. تحقق من الاتصال وحاول مجددًا.',
          clearNotice: true,
        ),
      );
    }
  }

  Future<_AppointmentsLoadResult> _loadDoctorAppointments(
    DoctorDashboardProfile _,
  ) async {
    try {
      final response = await api.get(EndPoints.myDoctorAppointments);
      final appointments =
          unwrapList(response, preferredKeys: const ['appointments'])
              .map(asStringMap)
              .whereType<Map<String, dynamic>>()
              .map(DoctorAppointment.fromJson)
              .toList();

      return _AppointmentsLoadResult(appointments: appointments);
    } on ServerExceptions catch (error) {
      return _AppointmentsLoadResult(
        appointments: const [],
        errorMessage: error.errModel.errorMessage,
      );
    } catch (_) {
      return const _AppointmentsLoadResult(
        appointments: [],
        errorMessage: 'تعذر جلب المواعيد من الخادم.',
      );
    }
  }

  Future<void> refreshLiveData() async {
    final profile = state.profile;
    if (profile == null || _liveRefreshLoading) return;
    _liveRefreshLoading = true;
    try {
      final responses = await Future.wait<dynamic>([
        _loadDoctorAppointments(profile),
        api.get(
          EndPoints.notifications,
          queryParameters: {'per_page': 50, 'unread_only': false},
        ),
        api.get(EndPoints.unreadNotificationsCount),
      ]);
      if (isClosed) return;
      final appointmentsResult = responses[0] as _AppointmentsLoadResult;
      final notifications =
          unwrapList(responses[1], preferredKeys: const ['notifications'])
              .map(asStringMap)
              .whereType<Map<String, dynamic>>()
              .map(DoctorNotification.fromJson)
              .toList();
      final unreadMap = unwrapMap(responses[2]);
      emit(
        state.copyWith(
          appointments: appointmentsResult.appointments,
          notifications: notifications,
          unreadCount: _toInt(
            unreadMap['count'] ??
                unreadMap['unread_count'] ??
                notifications.where((item) => !item.isRead).length,
          ),
          appointmentsError: appointmentsResult.errorMessage,
          clearAppointmentsError: appointmentsResult.errorMessage == null,
        ),
      );
    } catch (_) {
      // Background refresh is intentionally silent; existing data stays visible.
    } finally {
      _liveRefreshLoading = false;
    }
  }

  Future<void> markNotificationRead(int id) async {
    if (id == 0) return;
    try {
      await api.post(EndPoints.readNotification(id));
      await _reloadNotifications();
    } on ServerExceptions catch (error) {
      emit(state.copyWith(errorMessage: error.errModel.errorMessage));
    }
  }

  Future<void> markAllNotificationsRead() async {
    if (state.unreadCount == 0) return;
    try {
      await api.post(EndPoints.readAllNotifications);
      await _reloadNotifications();
    } on ServerExceptions catch (error) {
      emit(state.copyWith(errorMessage: error.errModel.errorMessage));
    }
  }

  Future<bool> createMedicalRecord({
    required int appointmentId,
    required String diagnosis,
    required String bloodType,
    required String allergies,
    required String heartRate,
    required String diseases,
    required String notes,
    required bool referToPharmacist,
    required bool referToLaboratory,
    required String laboratoryNotes,
  }) async {
    emit(
      state.copyWith(actionLoading: true, clearError: true, clearNotice: true),
    );
    try {
      final data = <String, dynamic>{
        'appointment_id': appointmentId,
        'diagnosis': diagnosis.trim(),
        'blood_type': bloodType.trim(),
        'allergies': allergies.trim(),
        'diseases': diseases.trim(),
        'notes': notes.trim(),
        'refer_to_pharmacist': referToPharmacist,
        'refer_to_laboratory': referToLaboratory,
        'laboratory_notes': laboratoryNotes.trim(),
      };
      final parsedHeartRate = int.tryParse(heartRate.trim());
      if (parsedHeartRate != null) data['heart_rate'] = parsedHeartRate;

      await api.post(EndPoints.medicalRecords, data: data);
      emit(
        state.copyWith(
          actionLoading: false,
          notice: 'تم حفظ المعاينة والسجل الطبي بنجاح.',
        ),
      );
      await loadDashboard(showLoader: false);
      return true;
    } on ServerExceptions catch (error) {
      emit(
        state.copyWith(
          actionLoading: false,
          errorMessage: error.errModel.errorMessage,
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          actionLoading: false,
          errorMessage: 'تعذر حفظ المعاينة. حاول مجددًا.',
        ),
      );
      return false;
    }
  }

  Future<bool> updateMedicalRecord(
    int recordId,
    Map<String, dynamic> data,
  ) async {
    emit(
      state.copyWith(actionLoading: true, clearError: true, clearNotice: true),
    );
    try {
      await api.put(EndPoints.medicalRecordById(recordId), data: data);
      emit(
        state.copyWith(
          actionLoading: false,
          notice: 'تم تعديل السجل الطبي بنجاح.',
        ),
      );
      await loadDashboard(showLoader: false);
      return true;
    } on ServerExceptions catch (error) {
      emit(
        state.copyWith(
          actionLoading: false,
          errorMessage: error.errModel.errorMessage,
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          actionLoading: false,
          errorMessage: 'تعذر تعديل السجل الطبي. حاول مجدداً.',
        ),
      );
      return false;
    }
  }

  Future<bool> deleteMedicalRecord(int recordId) async {
    emit(
      state.copyWith(actionLoading: true, clearError: true, clearNotice: true),
    );
    try {
      await api.delete(EndPoints.medicalRecordById(recordId));
      emit(state.copyWith(actionLoading: false, notice: 'تم حذف السجل الطبي.'));
      await loadDashboard(showLoader: false);
      return true;
    } on ServerExceptions catch (error) {
      emit(
        state.copyWith(
          actionLoading: false,
          errorMessage: error.errModel.errorMessage,
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          actionLoading: false,
          errorMessage: 'تعذر حذف السجل الطبي. حاول مجدداً.',
        ),
      );
      return false;
    }
  }

  Future<DoctorPrescription?> loadPrescriptionDetails(
    int prescriptionId,
  ) async {
    try {
      final response = await api.get(
        EndPoints.prescriptionById(prescriptionId),
      );
      return DoctorPrescription.fromJson(
        (response as Map).cast<String, dynamic>(),
      );
    } on ServerExceptions catch (error) {
      emit(state.copyWith(errorMessage: error.errModel.errorMessage));
      return null;
    } catch (_) {
      emit(state.copyWith(errorMessage: 'تعذر تحميل تفاصيل الوصفة.'));
      return null;
    }
  }

  Future<bool> updatePrescription({
    required int prescriptionId,
    required int medicalRecordId,
    required String instructions,
    required String notes,
    required List<VisitMedicineInput> items,
  }) async {
    emit(
      state.copyWith(actionLoading: true, clearError: true, clearNotice: true),
    );
    try {
      await api.put(
        EndPoints.prescriptionById(prescriptionId),
        data: {
          'medical_record_id': medicalRecordId,
          'instructions': instructions.trim(),
          'notes': notes.trim(),
          'items': items.map((item) => item.toApiJson()).toList(),
        },
      );
      emit(
        state.copyWith(actionLoading: false, notice: 'تم تعديل الوصفة بنجاح.'),
      );
      await loadDashboard(showLoader: false);
      return true;
    } on ServerExceptions catch (error) {
      emit(
        state.copyWith(
          actionLoading: false,
          errorMessage: error.errModel.errorMessage,
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          actionLoading: false,
          errorMessage: 'تعذر تعديل الوصفة. حاول مجدداً.',
        ),
      );
      return false;
    }
  }

  Future<bool> deletePrescription(int prescriptionId) async {
    emit(
      state.copyWith(actionLoading: true, clearError: true, clearNotice: true),
    );
    try {
      await api.delete(EndPoints.deletePrescription(prescriptionId));
      emit(state.copyWith(actionLoading: false, notice: 'تم حذف الوصفة.'));
      await loadDashboard(showLoader: false);
      return true;
    } on ServerExceptions catch (error) {
      emit(
        state.copyWith(
          actionLoading: false,
          errorMessage: error.errModel.errorMessage,
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          actionLoading: false,
          errorMessage: 'تعذر حذف الوصفة. حاول مجدداً.',
        ),
      );
      return false;
    }
  }

  Future<bool> completeVisit({
    required int appointmentId,
    required String diagnosis,
    required String bloodType,
    required String allergies,
    required String heartRate,
    required String diseases,
    required String notes,
    required bool referToPharmacist,
    required bool referToLaboratory,
    required String laboratoryNotes,
    required String prescriptionInstructions,
    required String prescriptionNotes,
    required List<VisitMedicineInput> medicines,
  }) async {
    emit(
      state.copyWith(actionLoading: true, clearError: true, clearNotice: true),
    );
    try {
      final recordPayload = <String, dynamic>{
        'appointment_id': appointmentId,
        'diagnosis': diagnosis.trim(),
        'blood_type': bloodType.trim(),
        'allergies': allergies.trim(),
        'diseases': diseases.trim(),
        'notes': notes.trim(),
        'refer_to_pharmacist': referToPharmacist || medicines.isNotEmpty,
        'refer_to_laboratory': referToLaboratory,
        'laboratory_notes': laboratoryNotes.trim(),
      };
      final parsedHeartRate = int.tryParse(heartRate.trim());
      if (parsedHeartRate != null) {
        recordPayload['heart_rate'] = parsedHeartRate;
      }

      final recordResponse = await api.post(
        EndPoints.medicalRecords,
        data: recordPayload,
      );
      final recordMap = unwrapMap(
        recordResponse,
        preferredKeys: const ['medical_record', 'record'],
      );
      final medicalRecordId = _toInt(
        recordMap['id'] ??
            recordMap['medical_record_id'] ??
            (asStringMap(recordResponse)?['medical_record_id']),
      );

      if (medicines.isNotEmpty) {
        if (medicalRecordId == 0) {
          emit(
            state.copyWith(
              actionLoading: false,
              errorMessage:
                  'تم إنشاء السجل لكن الاستجابة لم تتضمن medical_record_id لإنشاء الوصفة.',
            ),
          );
          await loadDashboard(showLoader: false);
          return false;
        }
        await api.post(
          EndPoints.prescriptions,
          data: {
            'medical_record_id': medicalRecordId,
            'instructions': prescriptionInstructions.trim(),
            'notes': prescriptionNotes.trim(),
            'items': medicines.map((item) => item.toApiJson()).toList(),
          },
        );
      }

      await CacheHelper.removeData(key: _draftKey(appointmentId));
      emit(
        state.copyWith(
          actionLoading: false,
          notice: medicines.isEmpty
              ? 'تم حفظ السجل وإنهاء الزيارة بنجاح.'
              : 'تم حفظ السجل والوصفة وإنهاء الزيارة بنجاح.',
        ),
      );
      await loadDashboard(showLoader: false);
      return true;
    } on ServerExceptions catch (error) {
      emit(
        state.copyWith(
          actionLoading: false,
          errorMessage: error.errModel.errorMessage,
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          actionLoading: false,
          errorMessage: 'تعذر إنهاء الزيارة. تحقق من البيانات وحاول مجددًا.',
        ),
      );
      return false;
    }
  }

  Future<void> saveVisitDraft({
    required int appointmentId,
    required Map<String, dynamic> data,
  }) async {
    await CacheHelper.saveData(
      key: _draftKey(appointmentId),
      value: jsonEncode(data),
    );
    emit(state.copyWith(notice: 'تم حفظ مسودة الزيارة على الجهاز.'));
  }

  Map<String, dynamic>? readVisitDraft(int appointmentId) {
    final raw = CacheHelper.getDataString(key: _draftKey(appointmentId));
    if (raw == null || raw.isEmpty) return null;
    try {
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  String _draftKey(int appointmentId) => 'doctor_visit_draft_$appointmentId';

  void clearMessages() {
    emit(state.copyWith(clearError: true, clearNotice: true));
  }

  Future<void> _reloadNotifications() async {
    final responses = await Future.wait<dynamic>([
      api.get(
        EndPoints.notifications,
        queryParameters: {'per_page': 50, 'unread_only': false},
      ),
      api.get(EndPoints.unreadNotificationsCount),
    ]);
    final notifications =
        unwrapList(responses[0], preferredKeys: const ['notifications'])
            .map(asStringMap)
            .whereType<Map<String, dynamic>>()
            .map(DoctorNotification.fromJson)
            .toList();
    final unreadMap = unwrapMap(responses[1]);
    emit(
      state.copyWith(
        notifications: notifications,
        unreadCount: _toInt(
          unreadMap['count'] ??
              unreadMap['unread_count'] ??
              notifications.where((item) => !item.isRead).length,
        ),
        clearError: true,
      ),
    );
  }

  Future<dynamic> _safeRequest(
    Future<dynamic> Function() request,
    String label,
    List<String> warnings,
  ) async {
    try {
      return await request();
    } catch (_) {
      warnings.add(label);
      return const <String, dynamic>{};
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _AppointmentsLoadResult {
  final List<DoctorAppointment> appointments;
  final String? errorMessage;

  const _AppointmentsLoadResult({
    required this.appointments,
    this.errorMessage,
  });
}
