import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/states/points_history_state.dart';
import 'package:nabad/Models/points_model.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';
import 'package:nabad/core/Error/exceptions.dart';

class PointsHistoryCubit extends Cubit<PointsHistoryState> {
  final ApiConsumer api;

  PointsHistoryCubit({required this.api}) : super(PointsHistoryInitial());

  Future<void> loadHistory({bool refresh = false}) async {
    final previous = state;
    if (!refresh && previous is PointsHistorySuccess && previous.loadingMore) {
      return;
    }

    final int page;
    if (refresh || previous is! PointsHistorySuccess) {
      emit(PointsHistoryLoading());
      page = 1;
    } else {
      if (!previous.hasMore) return;
      emit(previous.copyWith(loadingMore: true));
      page = previous.currentPage + 1;
    }

    try {
      final response = await api.get(
        EndPoints.pointsTransactions,
        queryParameters: {'per_page': 15, 'page': page},
      );
      final map = (response as Map).cast<String, dynamic>();
      final rawData = map['data'];
      final newItems = rawData is List
          ? rawData
                .whereType<Map>()
                .map(
                  (item) => PointTransactionModel.fromJson(
                    item.cast<String, dynamic>(),
                  ),
                )
                .toList()
          : <PointTransactionModel>[];
      final meta = (map['meta'] as Map?)?.cast<String, dynamic>() ?? {};
      final currentPage = _toInt(meta['current_page'], fallback: page);
      final lastPage = _toInt(meta['last_page'], fallback: currentPage);
      final oldItems = previous is PointsHistorySuccess && page > 1
          ? previous.transactions
          : <PointTransactionModel>[];

      emit(
        PointsHistorySuccess(
          transactions: [...oldItems, ...newItems],
          currentPage: currentPage,
          lastPage: lastPage,
        ),
      );
    } on ServerExceptions catch (e) {
      if (previous is PointsHistorySuccess) {
        emit(previous.copyWith(loadingMore: false));
      } else {
        emit(PointsHistoryError(message: e.errModel.errorMessage));
      }
    } catch (_) {
      if (previous is PointsHistorySuccess) {
        emit(previous.copyWith(loadingMore: false));
      } else {
        emit(PointsHistoryError(message: 'تعذر تحميل سجل النقاط'));
      }
    }
  }

  int _toInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
