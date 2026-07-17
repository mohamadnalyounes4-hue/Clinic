import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/states/appointment_state.dart';
import 'package:nabad/Models/appointment_model.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';
import 'package:nabad/core/Error/exceptions.dart';

class AppointmentCubit extends Cubit<AppointmentState> {
  final ApiConsumer api;

  AppointmentCubit({required this.api}) : super(AppointmentInitial());

  Future<void> getAppointments() async {
    emit(AppointmentLoading());
    try {
      final response = await api.get(EndPoints.appointments);
      final List data = response['data'] ?? [];
      final appointments = data
          .whereType<Map<String, dynamic>>()
          .map(AppointmentModel.fromJson)
          .toList();
      emit(AppointmentSuccess(appointments: appointments));
    } on ServerExceptions catch (e) {
      emit(AppointmentError(message: e.errModel.errorMessage));
    } catch (e) {
      emit(AppointmentError(message: 'حدث خطأ في جلب المواعيد'));
    }
  }

  /// الباك بيرفض غير كده: الموعد لازم completed، والتقييم 1-10، ومش
  Future<void> rateAppointment(int id, int rating) async {
    try {
      await api.post(EndPoints.rateAppointment(id), data: {'rating': rating});
      await getAppointments();
    } on ServerExceptions {
      rethrow;
    }
  }

  /// يحجز موعد جديد. بيرجع AppointmentModel المحجوز عند النجاح، وبيرمي
  /// ServerExceptions عند الفشل (422) لأي سبب من دول: الطبيب ما بيشتغلش
  /// اليوم ده، الوقت خارج الدوام، تعارض مع موعد تاني (للطبيب أو للمريض)،
  /// الرصيد مش كافي، أو النقاط مش كافية.
  Future<AppointmentModel> bookAppointment({
    required int doctorId,
    required DateTime date,
    required String time, // "HH:mm"
    int pointsToRedeem = 0,
  }) async {
    try {
      final response = await api.post(
        EndPoints.appointments,
        data: {
          'doctor_id': doctorId,
          'appointment_date': _formatDate(date),
          'appointment_time': time,
          'points_to_redeem': pointsToRedeem,
        },
      );
      final data = (response['data'] ?? response) as Map<String, dynamic>;
      final appointment = AppointmentModel.fromJson(data);
      await getAppointments();
      return appointment;
    } on ServerExceptions {
      rethrow;
    }
  }

  /// يعيد جدولة موعد قائم (تاريخ/وقت جديد) ثم يعيد جلب القائمة.
  /// الباك بيرفض غير كده لو الموعد مش confirmed. التعديل مبيعيدش خصم/دفع،
  /// بس بيتفحص التعارضات تاني.
  Future<void> rescheduleAppointment({
    required int id,
    required DateTime date,
    required String time, // "HH:mm"
  }) async {
    try {
      await api.put(
        EndPoints.updateAppointment(id),
        data: {'appointment_date': _formatDate(date), 'appointment_time': time},
      );
      await getAppointments();
    } on ServerExceptions {
      rethrow;
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// أقرب موعد قادم (confirmed) لعرضه في الصفحة الرئيسية، أو null لو مفيش.
  AppointmentModel? get nextUpcoming {
    final currentState = state;
    if (currentState is! AppointmentSuccess) return null;

    final upcoming = currentState.appointments
        .where((a) => a.isUpcoming)
        .toList();
    if (upcoming.isEmpty) return null;

    upcoming.sort((a, b) {
      final dateA = a.dateTime;
      final dateB = b.dateTime;
      if (dateA == null || dateB == null) return 0;
      return dateA.compareTo(dateB);
    });
    return upcoming.first;
  }
}
