import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/cubits/support_cubit.dart';
import 'package:nabad/Cubits/states/support_state.dart';
import 'package:nabad/Models/support_ticket_model.dart';
import 'package:nabad/core/localization/app_localizations.dart';
import 'package:nabad/core/router/app_router.dart';
import 'package:nabad/core/theme/nabad_colors.dart';
import 'package:timezone/timezone.dart' as tz;

class SupportTicketsPage extends StatefulWidget {
  const SupportTicketsPage({super.key});

  @override
  State<SupportTicketsPage> createState() => _SupportTicketsPageState();
}

class _SupportTicketsPageState extends State<SupportTicketsPage> {
  @override
  void initState() {
    super.initState();
    context.read<SupportCubit>().loadTickets(refresh: true);
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
          title: Column(
            children: [
              Text(
                context.tr('الدعم الفني'),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                context.tr('محادثاتي وشكاواي'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: NabadColors.deepTeal,
          surfaceTintColor: Colors.transparent,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.createSupportChat),
          backgroundColor: NabadColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_comment_outlined),
          label: Text(
            context.tr('محادثة دعم جديدة'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: BlocConsumer<SupportCubit, SupportState>(
          listenWhen: (previous, current) =>
              previous.errorStatusCode != current.errorStatusCode ||
              previous.errorMessage != current.errorMessage,
          listener: (context, state) {
            if (state.errorStatusCode == 401) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.welcome,
                (_) => false,
              );
            }
          },
          builder: (context, state) {
            if (state.status == SupportLoadStatus.loading &&
                state.tickets.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == SupportLoadStatus.failure &&
                state.tickets.isEmpty) {
              return _SupportMessageView(
                icon: Icons.cloud_off_rounded,
                title: context.tr(
                  state.errorMessage ?? 'تعذر تحميل محادثات الدعم.',
                ),
                actionLabel: context.tr('إعادة المحاولة'),
                onAction: () =>
                    context.read<SupportCubit>().loadTickets(refresh: true),
              );
            }
            if (state.tickets.isEmpty) {
              return _SupportMessageView(
                icon: Icons.forum_outlined,
                title: context.tr('لا توجد محادثات دعم حتى الآن'),
                subtitle: context.tr(
                  'ابدأ محادثة جديدة وسيظهر رد فريق الدعم هنا.',
                ),
                actionLabel: context.tr('إنشاء محادثة دعم'),
                onAction: () =>
                    Navigator.pushNamed(context, AppRoutes.createSupportChat),
              );
            }

            return RefreshIndicator(
              onRefresh: () =>
                  context.read<SupportCubit>().loadTickets(refresh: true),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
                itemCount: state.tickets.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final ticket = state.tickets[index];
                  return _ConversationTile(
                    ticket: ticket,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.supportChat,
                      arguments: ticket.id,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final SupportTicketModel ticket;
  final VoidCallback onTap;

  const _ConversationTile({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: NabadColors.softTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: NabadColors.primary,
                  size: 29,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ticket.subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: NabadColors.darkText,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          _supportTime(ticket.lastActivityAt),
                          style: const TextStyle(
                            color: NabadColors.mutedText,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      ticket.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: NabadColors.mutedText,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 7,
                      runSpacing: 5,
                      children: [
                        _Tag(
                          text: context.tr(_statusLabel(ticket.status)),
                          color: _statusColor(ticket.status),
                        ),
                        _Tag(
                          text: context.tr(_priorityLabel(ticket.priority)),
                          color: _priorityColor(ticket.priority),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;

  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withAlpha(22),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _SupportMessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _SupportMessageView({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: NabadColors.softTeal,
            child: Icon(icon, size: 40, color: NabadColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              color: NabadColors.darkText,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 7),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: NabadColors.mutedText),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    ),
  );
}

String _statusLabel(String value) => switch (value) {
  'in_progress' => 'قيد المعالجة',
  'resolved' => 'تم الحل',
  'closed' => 'مغلقة',
  _ => 'مفتوحة',
};

String _priorityLabel(String value) => switch (value) {
  'low' => 'أولوية منخفضة',
  'high' => 'أولوية عالية',
  'urgent' => 'عاجلة',
  _ => 'أولوية عادية',
};

Color _statusColor(String value) => switch (value) {
  'in_progress' => const Color(0xFF2879A5),
  'resolved' => const Color(0xFF19875D),
  'closed' => const Color(0xFF66747A),
  _ => NabadColors.primary,
};

Color _priorityColor(String value) => switch (value) {
  'high' => const Color(0xFFE07B2D),
  'urgent' => const Color(0xFFD74343),
  'low' => const Color(0xFF608096),
  _ => const Color(0xFF7867A6),
};

String _supportTime(DateTime? value) {
  if (value == null) return '';
  DateTime date;
  try {
    date = tz.TZDateTime.from(value, tz.getLocation('Asia/Damascus'));
  } catch (_) {
    date = value.toLocal();
  }
  final now = DateTime.now();
  if (now.year == date.year && now.month == date.month && now.day == date.day) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  return '${date.day}/${date.month}/${date.year}';
}
