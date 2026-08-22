import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/cubits/support_cubit.dart';
import 'package:nabad/Cubits/states/support_state.dart';
import 'package:nabad/Models/support_message_model.dart';
import 'package:nabad/Models/support_ticket_model.dart';
import 'package:nabad/core/localization/app_localizations.dart';
import 'package:nabad/core/router/app_router.dart';
import 'package:nabad/core/theme/nabad_colors.dart';
import 'package:timezone/timezone.dart' as tz;

class SupportChatPage extends StatefulWidget {
  final int ticketId;

  const SupportChatPage({super.key, required this.ticketId});

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<SupportCubit>().openTicket(widget.ticketId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final sent = await context.read<SupportCubit>().sendMessage(
      widget.ticketId,
      _messageController.text,
    );
    if (sent && mounted) {
      _messageController.clear();
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: context.l10n.isArabic
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: BlocConsumer<SupportCubit, SupportState>(
        listenWhen: (previous, current) =>
            previous.selectedTicket?.messages.length !=
                current.selectedTicket?.messages.length ||
            previous.actionError != current.actionError ||
            previous.errorStatusCode != current.errorStatusCode,
        listener: (context, state) {
          _scrollToBottom();
          final status = state.actionStatusCode ?? state.errorStatusCode;
          if (status == 401) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.welcome,
              (_) => false,
            );
            return;
          }
          if (state.actionError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.tr(state.actionError!)),
                action: SnackBarAction(
                  label: context.tr('إعادة المحاولة'),
                  onPressed: _send,
                ),
              ),
            );
            context.read<SupportCubit>().clearActionError();
          }
        },
        builder: (context, state) {
          final ticket = state.selectedTicket?.id == widget.ticketId
              ? state.selectedTicket
              : null;
          return Scaffold(
            backgroundColor: const Color(0xFFF4F8FA),
            appBar: AppBar(
              backgroundColor: Colors.white,
              foregroundColor: NabadColors.deepTeal,
              surfaceTintColor: Colors.transparent,
              titleSpacing: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket?.subject ?? context.tr('محادثة دعم'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (ticket != null)
                    Text(
                      context.tr(_chatStatusLabel(ticket.status)),
                      style: const TextStyle(
                        color: NabadColors.mutedText,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: context.tr('تحديث'),
                  onPressed: state.refreshing
                      ? null
                      : () => context.read<SupportCubit>().openTicket(
                          widget.ticketId,
                        ),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            body: ticket == null
                ? _loadingOrError(context, state)
                : Column(
                    children: [
                      _ChatInfoBar(ticket: ticket),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () => context
                              .read<SupportCubit>()
                              .openTicket(widget.ticketId),
                          child: ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
                            itemCount: ticket.messages.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _ChatBubble(
                                  text: ticket.description,
                                  isPatient: true,
                                  author: ticket.patientName,
                                  createdAt: ticket.createdAt,
                                );
                              }
                              final message = ticket.messages[index - 1];
                              return _MessageBubble(message: message);
                            },
                          ),
                        ),
                      ),
                      _MessageComposer(
                        controller: _messageController,
                        sending: state.sending,
                        onSend: _send,
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _loadingOrError(BuildContext context, SupportState state) {
    if (state.status == SupportLoadStatus.failure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 54,
                color: NabadColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                context.tr(state.errorMessage ?? 'المحادثة غير موجودة.'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () =>
                    context.read<SupportCubit>().openTicket(widget.ticketId),
                child: Text(context.tr('إعادة المحاولة')),
              ),
            ],
          ),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}

class _ChatInfoBar extends StatelessWidget {
  final SupportTicketModel ticket;

  const _ChatInfoBar({required this.ticket});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
    color: NabadColors.softTeal,
    child: Row(
      children: [
        const Icon(Icons.info_outline, size: 18, color: NabadColors.primary),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            '${context.tr('شكوى')} #${ticket.id} • ${context.tr(_chatPriorityLabel(ticket.priority))}',
            style: const TextStyle(
              color: NabadColors.deepTeal,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  final SupportMessageModel message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) => _ChatBubble(
    text: message.message,
    isPatient: message.isFromPatient,
    author: message.author,
    createdAt: message.createdAt,
  );
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isPatient;
  final String author;
  final DateTime? createdAt;

  const _ChatBubble({
    required this.text,
    required this.isPatient,
    required this.author,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) => Align(
    alignment: isPatient
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart,
    child: Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * .78,
      ),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(13, 9, 13, 8),
      decoration: BoxDecoration(
        color: isPatient ? NabadColors.primary : Colors.white,
        borderRadius: BorderRadiusDirectional.only(
          topStart: const Radius.circular(18),
          topEnd: const Radius.circular(18),
          bottomStart: Radius.circular(isPatient ? 18 : 4),
          bottomEnd: Radius.circular(isPatient ? 4 : 18),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isPatient && author.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                author,
                style: const TextStyle(
                  color: NabadColors.primary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          Text(
            text,
            style: TextStyle(
              color: isPatient ? Colors.white : NabadColors.darkText,
              fontSize: 14,
              height: 1.42,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _chatTime(createdAt),
            style: TextStyle(
              color: isPatient ? Colors.white70 : NabadColors.mutedText,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    ),
  );
}

class _MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _MessageComposer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: NabadColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              enabled: !sending,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: context.tr('اكتب رسالتك...'),
                filled: true,
                fillColor: const Color(0xFFF0F5F6),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: context.tr('إرسال'),
            onPressed: sending ? null : onSend,
            style: IconButton.styleFrom(
              backgroundColor: NabadColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: NabadColors.mutedText,
            ),
            icon: sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    ),
  );
}

String _chatStatusLabel(String value) => switch (value) {
  'in_progress' => 'قيد المعالجة',
  'resolved' => 'تم الحل',
  'closed' => 'مغلقة',
  _ => 'مفتوحة',
};

String _chatPriorityLabel(String value) => switch (value) {
  'low' => 'أولوية منخفضة',
  'high' => 'أولوية عالية',
  'urgent' => 'عاجلة',
  _ => 'أولوية عادية',
};

String _chatTime(DateTime? value) {
  if (value == null) return '';
  DateTime date;
  try {
    date = tz.TZDateTime.from(value, tz.getLocation('Asia/Damascus'));
  } catch (_) {
    date = value.toLocal();
  }
  return '${date.day}/${date.month}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
