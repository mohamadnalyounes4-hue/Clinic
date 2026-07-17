import 'package:nabad/Models/points_model.dart';

abstract class PointsState {}

class PointsInitial extends PointsState {}

class PointsLoading extends PointsState {}

class PointsSuccess extends PointsState {
  final PointsSummaryModel summary;
  PointsSuccess({required this.summary});
}

class PointsError extends PointsState {
  final String message;
  PointsError({required this.message});
}