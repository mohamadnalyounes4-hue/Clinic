import 'package:nabad/Models/points_model.dart';

sealed class PointsHistoryState {}

class PointsHistoryInitial extends PointsHistoryState {}

class PointsHistoryLoading extends PointsHistoryState {}

class PointsHistorySuccess extends PointsHistoryState {
  final List<PointTransactionModel> transactions;
  final int currentPage;
  final int lastPage;
  final bool loadingMore;

  PointsHistorySuccess({
    required this.transactions,
    required this.currentPage,
    required this.lastPage,
    this.loadingMore = false,
  });

  bool get hasMore => currentPage < lastPage;

  PointsHistorySuccess copyWith({
    List<PointTransactionModel>? transactions,
    int? currentPage,
    int? lastPage,
    bool? loadingMore,
  }) {
    return PointsHistorySuccess(
      transactions: transactions ?? this.transactions,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

class PointsHistoryError extends PointsHistoryState {
  final String message;
  PointsHistoryError({required this.message});
}
