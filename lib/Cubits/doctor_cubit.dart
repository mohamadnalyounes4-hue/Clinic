import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/clinic_states.dart';
import 'package:nabad/Models/doctor_model.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';
import 'package:nabad/core/Error/exceptions.dart';

class DoctorCubit extends Cubit<DoctorState> {
  final ApiConsumer api;

  DoctorCubit({required this.api}) : super(DoctorInitial());

  Future<void> getAllDoctors() async {
    emit(DoctorLoading());
    try {
      final response = await api.get(EndPoints.allDoctors);
      final doctors = _doctorsFromResponse(response);
      emit(DoctorSuccess(doctors: doctors));
    } on ServerExceptions catch (e) {
      emit(DoctorError(message: e.errModel.errorMessage));
    } catch (e) {
      emit(DoctorError(message: 'حدث خطأ في جلب قائمة الأطباء'));
    }
  }

  Future<void> getDoctorsByDepartment(int departmentId) async {
    emit(DoctorLoading());
    try {
      final response = await api.get(
        EndPoints.doctorsByDepartment(departmentId),
      );
      final doctors = _doctorsFromResponse(response);
      emit(DoctorSuccess(doctors: doctors));
    } on ServerExceptions catch (e) {
      emit(DoctorError(message: e.errModel.errorMessage));
    } catch (e) {
      emit(DoctorError(message: 'حدث خطأ في جلب أطباء التخصص'));
    }
  }

  List<DoctorModel> _doctorsFromResponse(dynamic response) {
    final dynamic rawData = response is List ? response : response['data'];
    if (rawData is! List) return [];

    return rawData
        .whereType<Map<String, dynamic>>()
        .map(DoctorModel.fromJson)
        .toList();
  }
}
