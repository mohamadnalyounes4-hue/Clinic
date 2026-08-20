import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/states/points_state.dart';
import 'package:nabad/Models/points_model.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';
import 'package:nabad/core/Error/exceptions.dart';

class PointsCubit extends Cubit<PointsState> {
  final ApiConsumer api;
  PointsSummaryModel? _lastSummary;
  bool _isLoading = false;

  PointsCubit({required this.api}) : super(PointsInitial());

  Future<void> getPointsSummary() async {
    if (_isLoading) return;
    _isLoading = true;
    if (_lastSummary == null) emit(PointsLoading());
    try {
      final response = await api.get(EndPoints.points);
      final summary = PointsSummaryModel.fromJson(
        (response as Map).cast<String, dynamic>(),
      );
      final change = _lastSummary == null
          ? 0
          : summary.pointsBalance - _lastSummary!.pointsBalance;
      _lastSummary = summary;
      emit(PointsSuccess(summary: summary, pointsChange: change));
    } on ServerExceptions catch (e) {
      if (_lastSummary == null) {
        emit(PointsError(message: e.errModel.errorMessage));
      }
    } catch (_) {
      if (_lastSummary == null) {
        emit(PointsError(message: 'تعذر تحميل رصيد النقاط'));
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<PointsRedemptionPreviewModel> previewRedemption({
    required int doctorId,
    required int pointsToRedeem,
  }) async {
    final response = await api.post(
      EndPoints.pointsPreview,
      data: {'doctor_id': doctorId, 'points_to_redeem': pointsToRedeem},
    );
    return PointsRedemptionPreviewModel.fromJson(
      (response as Map).cast<String, dynamic>(),
    );
  }
}
