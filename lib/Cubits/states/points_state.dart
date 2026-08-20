import 'package:nabad/Models/points_model.dart';

abstract class PointsState {}

class PointsInitial extends PointsState {}

class PointsLoading extends PointsState {}

class PointsSuccess extends PointsState {
  final PointsSummaryModel summary;
  final int? _pointsChange;

  int get pointsChange => _pointsChange ?? 0;

  PointsSuccess({required this.summary, int pointsChange = 0})
    : _pointsChange = pointsChange;
}

class PointsError extends PointsState {
  final String message;
  PointsError({required this.message});
}
