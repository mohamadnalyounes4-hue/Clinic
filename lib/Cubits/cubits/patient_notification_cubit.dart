import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/states/patient_notification_state.dart';
import 'package:nabad/Models/patient_notification_model.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';
import 'package:nabad/core/Error/exceptions.dart';

class PatientNotificationCubit extends Cubit<PatientNotificationState> {
  final ApiConsumer api;

  PatientNotificationCubit({required this.api})
    : super(const PatientNotificationState());

  Future<void> loadUnreadCount() async {
    try {
      final response = await api.get(EndPoints.unreadNotificationsCount);
      final map = (response as Map).cast<String, dynamic>();
      emit(state.copyWith(unreadCount: _toInt(map['count']), clearError: true));
    } catch (_) {
      // The badge is supplementary and must not block the patient home page.
    }
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    if (state.loadingMore) return;
    final page = refresh ? 1 : (state.hasMore ? state.currentPage + 1 : 1);
    if (!refresh &&
        state.status == PatientNotificationStatus.success &&
        !state.hasMore) {
      return;
    }

    if (refresh || state.status == PatientNotificationStatus.initial) {
      emit(state.copyWith(status: PatientNotificationStatus.loading));
    } else {
      emit(state.copyWith(loadingMore: true));
    }

    try {
      final responses = await Future.wait<dynamic>([
        api.get(
          EndPoints.notifications,
          queryParameters: {'per_page': 15, 'page': page},
        ),
        api.get(EndPoints.unreadNotificationsCount),
      ]);
      final response = (responses[0] as Map).cast<String, dynamic>();
      final rawList = response['data'];
      final items = rawList is List
          ? rawList
                .whereType<Map>()
                .map(
                  (item) => PatientNotificationModel.fromJson(
                    item.cast<String, dynamic>(),
                  ),
                )
                .toList()
          : <PatientNotificationModel>[];
      final meta = (response['meta'] as Map?)?.cast<String, dynamic>() ?? {};
      final countMap = (responses[1] as Map).cast<String, dynamic>();
      final previous = page > 1
          ? state.notifications
          : <PatientNotificationModel>[];

      emit(
        state.copyWith(
          status: PatientNotificationStatus.success,
          notifications: [...previous, ...items],
          unreadCount: _toInt(countMap['count']),
          currentPage: _toInt(meta['current_page'], fallback: page),
          lastPage: _toInt(meta['last_page'], fallback: page),
          loadingMore: false,
          clearError: true,
        ),
      );
    } on ServerExceptions catch (error) {
      _emitFailure(error.errModel.errorMessage);
    } catch (_) {
      _emitFailure('تعذر تحميل الإشعارات. تحقق من الاتصال وحاول مجدداً.');
    }
  }

  Future<void> markAsRead(int id) async {
    final index = state.notifications.indexWhere((item) => item.id == id);
    if (index < 0 || state.notifications[index].isRead) return;

    final updated = [...state.notifications];
    updated[index] = updated[index].copyWith(isRead: true);
    emit(
      state.copyWith(
        notifications: updated,
        unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
      ),
    );

    try {
      await api.post(EndPoints.readNotification(id));
    } on ServerExceptions catch (error) {
      emit(state.copyWith(errorMessage: error.errModel.errorMessage));
      await loadNotifications(refresh: true);
    }
  }

  Future<void> markAllAsRead() async {
    if (state.unreadCount == 0) return;
    try {
      await api.post(EndPoints.readAllNotifications);
      emit(
        state.copyWith(
          unreadCount: 0,
          notifications: state.notifications
              .map((item) => item.copyWith(isRead: true))
              .toList(),
          clearError: true,
        ),
      );
    } on ServerExceptions catch (error) {
      emit(state.copyWith(errorMessage: error.errModel.errorMessage));
    }
  }

  void clearError() => emit(state.copyWith(clearError: true));

  void _emitFailure(String message) {
    if (state.notifications.isEmpty) {
      emit(
        state.copyWith(
          status: PatientNotificationStatus.failure,
          loadingMore: false,
          errorMessage: message,
        ),
      );
    } else {
      emit(state.copyWith(loadingMore: false, errorMessage: message));
    }
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
