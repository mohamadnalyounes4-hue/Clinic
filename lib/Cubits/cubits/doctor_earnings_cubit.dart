import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/states/doctor_earnings_state.dart';
import 'package:nabad/Models/doctor_earnings_model.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';
import 'package:nabad/core/Error/exceptions.dart';

class DoctorEarningsCubit extends Cubit<DoctorEarningsState> {
  final ApiConsumer api;
  bool _loading = false;

  DoctorEarningsCubit({required this.api})
    : super(const DoctorEarningsInitial());

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    emit(const DoctorEarningsLoading());
    try {
      final response = await api.get(EndPoints.doctorEarnings);
      emit(
        DoctorEarningsSuccess(
          DoctorEarningsModel.fromJson(
            (response as Map).cast<String, dynamic>(),
          ),
        ),
      );
    } on ServerExceptions catch (error) {
      emit(DoctorEarningsError(error.errModel.errorMessage));
    } catch (_) {
      emit(const DoctorEarningsError('تعذر تحميل سجل الأرباح'));
    } finally {
      _loading = false;
    }
  }
}
