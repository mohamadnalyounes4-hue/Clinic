import 'package:nabad/Models/wallet_model.dart';

abstract class WalletState {}

class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletSuccess extends WalletState {
  final WalletModel wallet;
  final List<WalletTransactionModel> transactions;

  WalletSuccess({required this.wallet, required this.transactions});
}

class WalletError extends WalletState {
  final String message;
  WalletError({required this.message});
}