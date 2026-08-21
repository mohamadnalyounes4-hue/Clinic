import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/cubits/points_cubit.dart';
import 'package:nabad/Cubits/cubits/points_history_cubit.dart';
import 'package:nabad/Cubits/states/points_history_state.dart';
import 'package:nabad/Cubits/states/points_state.dart';
import 'package:nabad/Models/points_model.dart';
import 'package:nabad/core/localization/app_localizations.dart';
import 'package:nabad/core/theme/nabad_colors.dart';

class PointsHistoryScreen extends StatefulWidget {
  const PointsHistoryScreen({super.key});

  @override
  State<PointsHistoryScreen> createState() => _PointsHistoryScreenState();
}

class _PointsHistoryScreenState extends State<PointsHistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<PointsCubit>().getPointsSummary();
    context.read<PointsHistoryCubit>().loadHistory(refresh: true);
    _scrollController.addListener(_loadMore);
  }

  void _loadMore() {
    if (_scrollController.position.extentAfter < 250) {
      context.read<PointsHistoryCubit>().loadHistory();
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<PointsCubit>().getPointsSummary(),
      context.read<PointsHistoryCubit>().loadHistory(refresh: true),
    ]);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMore)
      ..dispose();
    super.dispose();
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
          title: Text(context.tr('نقاطي')),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: NabadColors.deepTeal,
          surfaceTintColor: Colors.transparent,
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: _PointsSummaryCard()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                  child: Text(
                    context.tr('سجل الحركات'),
                    style: const TextStyle(
                      color: NabadColors.darkText,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              BlocBuilder<PointsHistoryCubit, PointsHistoryState>(
                builder: (context, state) {
                  if (state is PointsHistoryInitial ||
                      state is PointsHistoryLoading) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (state is PointsHistoryError) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: _ErrorView(
                        message: state.message,
                        onRetry: () => context
                            .read<PointsHistoryCubit>()
                            .loadHistory(refresh: true),
                      ),
                    );
                  }

                  final success = state as PointsHistorySuccess;
                  if (success.transactions.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyView(),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.separated(
                      itemCount:
                          success.transactions.length +
                          (success.loadingMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index == success.transactions.length) {
                          return const Padding(
                            padding: EdgeInsets.all(14),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        return _TransactionCard(
                          transaction: success.transactions[index],
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PointsSummaryCard extends StatelessWidget {
  const _PointsSummaryCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PointsCubit, PointsState>(
      builder: (context, state) {
        final summary = state is PointsSuccess ? state.summary : null;
        return Container(
          margin: const EdgeInsets.all(16),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF35AFC5), NabadColors.primary],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: NabadColors.primary.withAlpha(45),
                blurRadius: 26,
                offset: const Offset(0, 13),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: -28,
                top: -38,
                child: Icon(
                  Icons.stars_rounded,
                  size: 170,
                  color: Colors.white.withAlpha(15),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: state is PointsLoading || state is PointsInitial
                    ? const SizedBox(
                        height: 150,
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      )
                    : state is PointsError
                    ? SizedBox(
                        height: 100,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                context.tr(state.message),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _SummaryContent(summary: summary!),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryContent extends StatelessWidget {
  final PointsSummaryModel summary;
  const _SummaryContent({required this.summary});

  @override
  Widget build(BuildContext context) {
    final unit = summary.pointsPerUnit;
    final availableDiscounts = unit > 0 ? summary.pointsBalance ~/ unit : 0;
    final availablePercent = (availableDiscounts * summary.discountPerUnit)
        .clamp(0, summary.maxDiscountPercent);
    final remainder = unit > 0 ? summary.pointsBalance % unit : 0;
    final progress = unit > 0 ? remainder / unit : 0.0;
    final left = unit > 0 ? unit - remainder : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(28),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: Colors.white.withAlpha(36)),
              ),
              child: const Icon(
                Icons.stars_rounded,
                color: NabadColors.starColor,
                size: 30,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('رصيدك الحالي'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${summary.pointsBalance}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 31,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 5, bottom: 3),
                        child: Text(
                          context.tr('نقطة'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withAlpha(25)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      availableDiscounts > 0
                          ? context.tr('خصم {percent}% جاهز', {
                              'percent': availablePercent.toStringAsFixed(0),
                            })
                          : context.tr('نحو الخصم القادم'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${summary.discountPerUnit.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: NabadColors.starColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: availableDiscounts > 0 ? 1 : progress,
                  minHeight: 7,
                  backgroundColor: Colors.white.withAlpha(28),
                  valueColor: const AlwaysStoppedAnimation(
                    NabadColors.starColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  availableDiscounts > 0
                      ? context.tr('استخدم نقاطك عند حجز موعد جديد')
                      : context.tr(
                          'باقي {left} نقطة للوصول إلى {target} نقطة',
                          {'left': left, 'target': summary.pointsPerUnit},
                        ),
                  style: TextStyle(
                    color: Colors.white.withAlpha(205),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Colors.white70,
              size: 15,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                context
                    .tr('كل {unit} نقطة تمنحك خصماً {discount}% — حتى {max}%', {
                      'unit': summary.pointsPerUnit,
                      'discount': summary.discountPerUnit.toStringAsFixed(0),
                      'max': summary.maxDiscountPercent.toStringAsFixed(0),
                    }),
                style: const TextStyle(color: Colors.white70, fontSize: 10.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            const Icon(Icons.add_task_rounded, color: Colors.white70, size: 15),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                context.tr('كل موعد تحجزه يمنحك 20 نقطة بعد اكتماله'),
                style: const TextStyle(color: Colors.white70, fontSize: 10.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final PointTransactionModel transaction;
  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final credit = transaction.isCredit;
    final color = credit ? const Color(0xFF17875D) : const Color(0xFFC14C4C);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: NabadColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withAlpha(22),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(_typeIcon(transaction.type), color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(_typeLabel(transaction.type)),
                  style: const TextStyle(
                    color: NabadColors.darkText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (transaction.type == 'admin_adjustment' &&
                    transaction.description != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    transaction.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: NabadColors.mutedText,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  transaction.createdAt,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: NabadColors.mutedText,
                    fontSize: 12,
                  ),
                ),
                if (transaction.appointmentDate != null)
                  Text(
                    '${context.tr('موعد')} ${transaction.appointmentDate} ${transaction.appointmentTime ?? ''}',
                    style: const TextStyle(
                      color: NabadColors.mutedText,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${credit ? '+' : ''}${transaction.points}',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${context.tr('الرصيد')} ${transaction.balanceAfter}',
                style: const TextStyle(
                  color: NabadColors.mutedText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'earn_completed':
        return 'نقاط إتمام موعد';
      case 'redeem_booking':
        return 'استخدام نقاط في حجز';
      case 'refund_cancel':
        return 'استرجاع نقاط موعد';
      case 'admin_adjustment':
        return 'تعديل رصيد النقاط';
      default:
        return 'حركة نقاط';
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'earn_completed':
        return Icons.check_circle_outline_rounded;
      case 'redeem_booking':
        return Icons.local_offer_outlined;
      case 'refund_cancel':
        return Icons.replay_rounded;
      case 'admin_adjustment':
        return Icons.tune_rounded;
      default:
        return transaction.isCredit ? Icons.add_rounded : Icons.remove_rounded;
    }
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_outlined, size: 60, color: NabadColors.primary),
          SizedBox(height: 14),
          Text(
            context.tr('لا توجد حركات نقاط حتى الآن'),
            style: const TextStyle(
              color: NabadColors.darkText,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 56,
            color: NabadColors.primary,
          ),
          const SizedBox(height: 12),
          Text(context.tr(message), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: Text(context.tr('إعادة المحاولة')),
          ),
        ],
      ),
    );
  }
}
