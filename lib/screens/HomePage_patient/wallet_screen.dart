import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/cubits/wallet_cubit.dart';
import 'package:nabad/Cubits/states/wallet_state.dart';
import 'package:nabad/Models/wallet_model.dart';
import 'package:nabad/core/localization/app_localizations.dart';
import 'package:nabad/core/theme/nabad_colors.dart';

class WalletScreen extends StatefulWidget {
  final String title;
  final bool allowTopUp;

  const WalletScreen({
    super.key,
    this.title = 'محفظتي',
    this.allowTopUp = true,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletCubit>().loadWallet();
    });
  }

  void _showTopUpNotice() {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: context.l10n.isArabic
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            context.tr('شحن المحفظة'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            context.tr(
              'شحن المحفظة متاح حاليًا من خلال العيادة مباشرة. تواصل مع الاستقبال لإضافة رصيد لمحفظتك.',
            ),
            style: const TextStyle(color: NabadColors.mutedText, height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.tr('حسناً'),
                style: const TextStyle(color: NabadColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: context.l10n.isArabic
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: NabadColors.background,
        appBar: AppBar(
          title: Text(context.tr(widget.title)),
          centerTitle: true,
          backgroundColor: NabadColors.background,
          elevation: 0,
          foregroundColor: NabadColors.darkText,
        ),
        body: BlocBuilder<WalletCubit, WalletState>(
          builder: (context, state) {
            if (state is WalletLoading || state is WalletInitial) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }

            if (state is WalletError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr(state.message),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: NabadColors.mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () =>
                            context.read<WalletCubit>().loadWallet(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(context.tr('إعادة المحاولة')),
                        style: TextButton.styleFrom(
                          foregroundColor: NabadColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final success = state as WalletSuccess;
            return RefreshIndicator(
              onRefresh: () => context.read<WalletCubit>().loadWallet(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _BalanceCard(
                    wallet: success.wallet,
                    onTopUp: widget.allowTopUp ? _showTopUpNotice : null,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.tr('سجل الحركات'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: NabadColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (success.transactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 56,
                              color: NabadColors.primary.withOpacity(0.25),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              context.tr('لا توجد حركات بعد'),
                              style: const TextStyle(
                                color: NabadColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...success.transactions.map(
                      (t) => _TransactionTile(transaction: t),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final WalletModel wallet;
  final VoidCallback? onTopUp;

  const _BalanceCard({required this.wallet, required this.onTopUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NabadColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: NabadColors.primary.withAlpha(40),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const Spacer(),
              Text(
                context.tr('رصيد المحفظة'),
                style: TextStyle(
                  color: Colors.white.withAlpha(215),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${wallet.balance.toStringAsFixed(0)} ${context.tr('ل.س')}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (onTopUp != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onTopUp,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: Text(context.tr('شحن المحفظة')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withAlpha(140)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WalletTransactionModel transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final color = isCredit ? const Color(0xFF2E7D32) : const Color(0xFFE53935);
    final sign = isCredit ? '+' : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NabadColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NabadColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.displayLabel,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: NabadColors.darkText,
                  ),
                ),
                if (transaction.createdAt != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    _formatDate(transaction.createdAt!),
                    style: const TextStyle(
                      fontSize: 11,
                      color: NabadColors.mutedText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                '$sign${transaction.amount.abs().toStringAsFixed(0)} ${context.tr('ل.س')}',
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
