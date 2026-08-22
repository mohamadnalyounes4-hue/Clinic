import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/cubits/doctor_earnings_cubit.dart';
import 'package:nabad/Cubits/states/doctor_earnings_state.dart';
import 'package:nabad/Models/doctor_earnings_model.dart';
import 'package:nabad/core/localization/app_localizations.dart';

const _purple = Color(0xFF5B4FD6);
const _blue = Color(0xFF2878E6);
const _ink = Color(0xFF172A35);
const _muted = Color(0xFF6D7882);

class DoctorEarningsPage extends StatefulWidget {
  const DoctorEarningsPage({super.key});

  @override
  State<DoctorEarningsPage> createState() => _DoctorEarningsPageState();
}

class _DoctorEarningsPageState extends State<DoctorEarningsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DoctorEarningsCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: context.l10n.isArabic
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('سجل أرباح الطبيب')),
          centerTitle: true,
        ),
        body: BlocBuilder<DoctorEarningsCubit, DoctorEarningsState>(
          builder: (context, state) {
            if (state is DoctorEarningsInitial ||
                state is DoctorEarningsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DoctorEarningsError) {
              return _ErrorState(
                message: state.message,
                onRetry: context.read<DoctorEarningsCubit>().load,
              );
            }
            final earnings = (state as DoctorEarningsSuccess).earnings;
            return RefreshIndicator(
              onRefresh: context.read<DoctorEarningsCubit>().load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _EarningsHero(summary: earnings.summary),
                  const SizedBox(height: 14),
                  _SummaryGrid(summary: earnings.summary),
                  const SizedBox(height: 24),
                  Text(
                    context.tr('سجل العمليات'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr(
                      'الأرقام معتمدة من السيرفر للمواعيد المكتملة فقط',
                    ),
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  if (earnings.ledger.isEmpty)
                    const _EmptyLedger()
                  else
                    ...earnings.ledger.map(_LedgerCard.new),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EarningsHero extends StatelessWidget {
  final DoctorEarningsSummary summary;

  const _EarningsHero({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_purple, _blue],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x335B4FD6),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                context.tr('صافي أرباحك'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '${_money(summary.doctorShare)} ${context.tr('ل.س')}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            context.tr('حصتك من المواعيد المكتملة'),
            style: TextStyle(color: Colors.white.withAlpha(205)),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final DoctorEarningsSummary summary;

  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.task_alt_rounded, 'المعاينات المكتملة', '${summary.appointments}'),
      (Icons.payments_outlined, 'إجمالي الدخل', _money(summary.gross)),
      (
        Icons.account_balance_outlined,
        'عمولة المنصة',
        _money(summary.platformShare),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 20) / 3;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0) const SizedBox(width: 10),
              SizedBox(
                width: width,
                child: _MetricCard(
                  icon: items[index].$1,
                  label: items[index].$2,
                  value: items[index].$3,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 126),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _purple.withAlpha(25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _purple, size: 21),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            context.tr(label),
            maxLines: 2,
            style: const TextStyle(color: _muted, fontSize: 11, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _LedgerCard extends StatelessWidget {
  final DoctorEarningsEntry entry;

  const _LedgerCard(this.entry);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0x145B4FD6),
                foregroundColor: _purple,
                child: Icon(Icons.receipt_long_rounded, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('الموعد رقم {id}', {
                        'id': entry.appointmentId,
                      }),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      entry.date,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '+${_money(entry.doctorShare)}',
                style: const TextStyle(
                  color: Color(0xFF178A55),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: [
              Expanded(child: _LedgerValue('الإجمالي', entry.gross)),
              Expanded(child: _LedgerValue('حصتك', entry.doctorShare)),
              Expanded(
                child: _LedgerValue('عمولة المنصة', entry.platformShare),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LedgerValue extends StatelessWidget {
  final String label;
  final double value;

  const _LedgerValue(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          context.tr(label),
          style: const TextStyle(color: _muted, fontSize: 10),
        ),
        const SizedBox(height: 3),
        FittedBox(
          child: Text(
            _money(value),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _EmptyLedger extends StatelessWidget {
  const _EmptyLedger();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(Icons.insights_rounded, size: 52, color: _purple),
          const SizedBox(height: 12),
          Text(
            context.tr('لا توجد أرباح مسجلة بعد'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            context.tr('تظهر الأرباح هنا بعد اكتمال المعاينات'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 50, color: _purple),
            const SizedBox(height: 12),
            Text(context.tr(message), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr('إعادة المحاولة')),
            ),
          ],
        ),
      ),
    );
  }
}

String _money(double value) {
  final fixed = value.toStringAsFixed(
    value.truncateToDouble() == value ? 0 : 2,
  );
  final parts = fixed.split('.');
  final digits = parts.first;
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return parts.length == 2 ? '$buffer.${parts[1]}' : '$buffer';
}
