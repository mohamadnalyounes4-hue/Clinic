import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/cubits/patient_notification_cubit.dart';
import 'package:nabad/Cubits/states/patient_notification_state.dart';
import 'package:nabad/Models/patient_notification_model.dart';
import 'package:nabad/core/theme/nabad_colors.dart';

class PatientNotificationsScreen extends StatefulWidget {
  const PatientNotificationsScreen({super.key});

  @override
  State<PatientNotificationsScreen> createState() =>
      _PatientNotificationsScreenState();
}

class _PatientNotificationsScreenState
    extends State<PatientNotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<PatientNotificationCubit>().loadNotifications(refresh: true);
    _scrollController.addListener(_loadMore);
  }

  void _loadMore() {
    if (_scrollController.position.extentAfter < 250) {
      context.read<PatientNotificationCubit>().loadNotifications();
    }
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
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: NabadColors.background,
        appBar: AppBar(
          title: const Text(
            'الإشعارات',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: NabadColors.deepTeal,
          surfaceTintColor: Colors.transparent,
          actions: [
            BlocBuilder<PatientNotificationCubit, PatientNotificationState>(
              buildWhen: (previous, current) =>
                  previous.unreadCount != current.unreadCount,
              builder: (context, state) {
                return TextButton(
                  onPressed: state.unreadCount == 0
                      ? null
                      : () => context
                            .read<PatientNotificationCubit>()
                            .markAllAsRead(),
                  child: const Text(
                    'قراءة الكل',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<PatientNotificationCubit, PatientNotificationState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage &&
              current.errorMessage != null,
          listener: (context, state) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            context.read<PatientNotificationCubit>().clearError();
          },
          builder: (context, state) {
            if (state.status == PatientNotificationStatus.loading &&
                state.notifications.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == PatientNotificationStatus.failure &&
                state.notifications.isEmpty) {
              return _MessageView(
                icon: Icons.cloud_off_rounded,
                title: state.errorMessage ?? 'تعذر تحميل الإشعارات',
                actionLabel: 'إعادة المحاولة',
                onAction: () => context
                    .read<PatientNotificationCubit>()
                    .loadNotifications(refresh: true),
              );
            }
            if (state.notifications.isEmpty) {
              return const _MessageView(
                icon: Icons.notifications_none_rounded,
                title: 'لا توجد إشعارات حتى الآن',
                subtitle: 'ستظهر هنا تحديثات مواعيدك ووصفاتك ومدفوعاتك.',
              );
            }

            return RefreshIndicator(
              onRefresh: () => context
                  .read<PatientNotificationCubit>()
                  .loadNotifications(refresh: true),
              child: ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                itemCount:
                    state.notifications.length + (state.loadingMore ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index == state.notifications.length) {
                    return const Padding(
                      padding: EdgeInsets.all(14),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  final notification = state.notifications[index];
                  return _NotificationCard(
                    notification: notification,
                    onTap: () => context
                        .read<PatientNotificationCubit>()
                        .markAsRead(notification.id),
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

class _NotificationCard extends StatelessWidget {
  final PatientNotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    final accent = _typeColor(notification.type);
    return Material(
      color: unread ? const Color(0xFFEAF8FA) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: unread
                  ? NabadColors.primary.withAlpha(45)
                  : NabadColors.divider,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withAlpha(22),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(_typeIcon(notification.type), color: accent),
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
                            notification.title,
                            style: TextStyle(
                              color: NabadColors.darkText,
                              fontSize: 14,
                              fontWeight: unread
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: NabadColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (notification.body.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        notification.body,
                        style: const TextStyle(
                          color: NabadColors.mutedText,
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(notification.createdAt),
                      style: TextStyle(
                        color: unread
                            ? NabadColors.primary
                            : NabadColors.mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
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

  static IconData _typeIcon(String type) {
    if (type.contains('appointment')) return Icons.calendar_month_outlined;
    if (type.contains('prescription') || type.contains('pharmacy')) {
      return Icons.medication_outlined;
    }
    if (type.contains('laboratory')) return Icons.biotech_outlined;
    if (type.contains('wallet') || type.contains('payment')) {
      return Icons.account_balance_wallet_outlined;
    }
    return Icons.notifications_none_rounded;
  }

  static Color _typeColor(String type) {
    if (type.contains('prescription') || type.contains('pharmacy')) {
      return const Color(0xFF6E5AA8);
    }
    if (type.contains('laboratory')) return const Color(0xFF2683A3);
    if (type.contains('wallet') || type.contains('payment')) {
      return const Color(0xFF17875D);
    }
    return NabadColors.primary;
  }

  static String _formatTime(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    final difference = DateTime.now().difference(local);
    if (!difference.isNegative) {
      if (difference.inMinutes < 1) return 'الآن';
      if (difference.inMinutes < 60) return 'منذ ${difference.inMinutes} دقيقة';
      if (difference.inHours < 24) return 'منذ ${difference.inHours} ساعة';
      if (difference.inDays < 7) return 'منذ ${difference.inDays} يوم';
    }
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year}  $hour:$minute';
  }
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageView({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: NabadColors.softTeal,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: NabadColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: NabadColors.darkText,
                fontSize: 17,
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
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
