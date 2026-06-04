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
      final List data = response['data'];
      final doctors = data
          .map((e) => DoctorModel.fromJson(e as Map<String, dynamic>))
          .toList();
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
      final List data = response['data'];
      final doctors = data
          .map((e) => DoctorModel.fromJson(e as Map<String, dynamic>))
          .toList();
      emit(DoctorSuccess(doctors: doctors));
    } on ServerExceptions catch (e) {
      emit(DoctorError(message: e.errModel.errorMessage));
    } catch (e) {
      emit(DoctorError(message: 'حدث خطأ في جلب أطباء التخصص'));
    }
  }
}
