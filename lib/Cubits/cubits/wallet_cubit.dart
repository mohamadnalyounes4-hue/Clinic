import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/states/wallet_state.dart';
import 'package:nabad/Models/wallet_model.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';
import 'package:nabad/core/Error/exceptions.dart';

class WalletCubit extends Cubit<WalletState> {
  final ApiConsumer api;

  WalletCubit({required this.api}) : super(WalletInitial());

  Future<void> loadWallet() async {
    emit(WalletLoading());
    try {
      final results = await Future.wait([
        api.get(EndPoints.wallet),
        api.get(
          EndPoints.walletTransactions,
          queryParameters: {'per_page': 15},
        ),
      ]);

      final wallet = WalletModel.fromJson(
        (results[0] as Map).cast<String, dynamic>(),
      );
      final page = WalletTransactionsPage.fromJson(results[1]);

      emit(WalletSuccess(wallet: wallet, transactions: page.transactions));
    } on ServerExceptions catch (e) {
      emit(WalletError(message: e.errModel.errorMessage));
    } catch (_) {
      emit(WalletError(message: 'تعذر تحميل بيانات المحفظة'));
    }
  }
}