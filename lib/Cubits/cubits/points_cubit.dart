import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/states/points_state.dart';
import 'package:nabad/Models/points_model.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';
import 'package:nabad/core/Error/exceptions.dart';

class PointsCubit extends Cubit<PointsState> {
  final ApiConsumer api;

  PointsCubit({required this.api}) : super(PointsInitial());

  Future<void> getPointsSummary() async {
    emit(PointsLoading());
    try {
      final response = await api.get(EndPoints.points);
      final summary = PointsSummaryModel.fromJson(
        (response as Map).cast<String, dynamic>(),
      );
      emit(PointsSuccess(summary: summary));
    } on ServerExceptions catch (e) {
      emit(PointsError(message: e.errModel.errorMessage));
    } catch (_) {
      emit(PointsError(message: 'تعذر تحميل رصيد النقاط'));
    }
  }
}