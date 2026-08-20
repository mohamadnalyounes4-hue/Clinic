import 'package:nabad/Models/patient_notification_model.dart';

enum PatientNotificationStatus { initial, loading, success, failure }

class PatientNotificationState {
  final PatientNotificationStatus status;
  final List<PatientNotificationModel> notifications;
  final int unreadCount;
  final int currentPage;
  final int lastPage;
  final bool loadingMore;
  final String? errorMessage;

  const PatientNotificationState({
    this.status = PatientNotificationStatus.initial,
    this.notifications = const [],
    this.unreadCount = 0,
    this.currentPage = 1,
    this.lastPage = 1,
    this.loadingMore = false,
    this.errorMessage,
  });

  bool get hasMore => currentPage < lastPage;

  PatientNotificationState copyWith({
    PatientNotificationStatus? status,
    List<PatientNotificationModel>? notifications,
    int? unreadCount,
    int? currentPage,
    int? lastPage,
    bool? loadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PatientNotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      loadingMore: loadingMore ?? this.loadingMore,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
