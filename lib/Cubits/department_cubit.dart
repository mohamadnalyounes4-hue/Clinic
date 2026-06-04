import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/clinic_states.dart';
import 'package:nabad/Models/department_model.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';
import 'package:nabad/core/Error/exceptions.dart';

class DepartmentCubit extends Cubit<DepartmentState> {
  final ApiConsumer api;

  DepartmentCubit({required this.api}) : super(DepartmentInitial());

  Future<void> getDepartments() async {
    emit(DepartmentLoading());
    try {
      final response = await api.get(EndPoints.departmentsOnly);
      final List data = response['data'];
      final departments = data
          .map((e) => DepartmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
      emit(DepartmentSuccess(departments: departments));
    } on ServerExceptions catch (e) {
      emit(DepartmentError(message: e.errModel.errorMessage));
    } catch (e) {
      emit(DepartmentError(message: 'حدث خطأ في جلب التخصصات'));
    }
  }
}
