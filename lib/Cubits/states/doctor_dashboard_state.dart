import 'package:nabad/Models/doctor_dashboard_model.dart';

enum DoctorDashboardStatus { initial, loading, success, failure }

class DoctorDashboardState {
  final DoctorDashboardStatus status;
  final DoctorDashboardProfile? profile;
  final List<DoctorAppointment> appointments;
  final List<DoctorNotification> notifications;
  final List<DoctorMedicalRecord> medicalRecords;
  final List<DoctorPrescription> prescriptions;
  final List<DoctorMedicine> medicines;
  final int unreadCount;
  final bool actionLoading;
  final String? errorMessage;
  final String? notice;
  final String? appointmentsError;

  const DoctorDashboardState({
    this.status = DoctorDashboardStatus.initial,
    this.profile,
    this.appointments = const [],
    this.notifications = const [],
    this.medicalRecords = const [],
    this.prescriptions = const [],
    this.medicines = const [],
    this.unreadCount = 0,
    this.actionLoading = false,
    this.errorMessage,
    this.notice,
    this.appointmentsError,
  });

  DoctorDashboardState copyWith({
    DoctorDashboardStatus? status,
    DoctorDashboardProfile? profile,
    List<DoctorAppointment>? appointments,
    List<DoctorNotification>? notifications,
    List<DoctorMedicalRecord>? medicalRecords,
    List<DoctorPrescription>? prescriptions,
    List<DoctorMedicine>? medicines,
    int? unreadCount,
    bool? actionLoading,
    String? errorMessage,
    bool clearError = false,
    String? notice,
    bool clearNotice = false,
    String? appointmentsError,
    bool clearAppointmentsError = false,
  }) {
    return DoctorDashboardState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      appointments: appointments ?? this.appointments,
      notifications: notifications ?? this.notifications,
      medicalRecords: medicalRecords ?? this.medicalRecords,
      prescriptions: prescriptions ?? this.prescriptions,
      medicines: medicines ?? this.medicines,
      unreadCount: unreadCount ?? this.unreadCount,
      actionLoading: actionLoading ?? this.actionLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      notice: clearNotice ? null : (notice ?? this.notice),
      appointmentsError: clearAppointmentsError
          ? null
          : (appointmentsError ?? this.appointmentsError),
    );
  }

  List<DoctorAppointment> get todayAppointments {
    final result = appointments.where((item) => item.isToday).toList();
    result.sort(_sortAppointments);
    return result;
  }

  List<DoctorAppointment> get upcomingAppointments {
    final now = DateTime.now();
    final result = appointments.where((item) {
      final dateTime = item.dateTime;
      return dateTime != null && !item.isFinished && !dateTime.isBefore(now);
    }).toList();
    result.sort(_sortAppointments);
    return result;
  }

  DoctorAppointment? get nextAppointment {
    final upcoming = upcomingAppointments;
    return upcoming.isEmpty ? null : upcoming.first;
  }

  int get waitingPatients =>
      todayAppointments.where((item) => item.isWaiting).length;

  static int _sortAppointments(DoctorAppointment a, DoctorAppointment b) {
    final first = a.dateTime;
    final second = b.dateTime;
    if (first == null && second == null) return 0;
    if (first == null) return 1;
    if (second == null) return -1;
    return first.compareTo(second);
  }
}
