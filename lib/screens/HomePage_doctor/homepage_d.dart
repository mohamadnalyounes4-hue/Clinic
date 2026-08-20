import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/cubits/doctor_dashboard_cubit.dart';
import 'package:nabad/Cubits/cubits/appointment_cubit.dart';
import 'package:nabad/Cubits/cubits/user_cubit.dart';
import 'package:nabad/Cubits/states/doctor_dashboard_state.dart';
import 'package:nabad/Cubits/states/user_state.dart';
import 'package:nabad/Models/doctor_dashboard_model.dart';
import 'package:nabad/Models/doctor_schedule_model.dart';
import 'package:nabad/Models/doctor_availability_model.dart';
import 'package:nabad/core/router/app_router.dart';
import 'package:nabad/screens/HomePage_patient/wallet_screen.dart';

const _ink = Color(0xFF172A35);
const _muted = Color(0xFF697783);
const _background = Color(0xFFF7FBFD);
const _teal = Color(0xFF047C87);
const _deepTeal = Color(0xFF006B75);
const _paleTeal = Color(0xFFE2F5F7);
const _danger = Color(0xFFC91F2A);

class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({super.key});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DoctorDashboardCubit>().loadDashboard();
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) context.read<DoctorDashboardCubit>().refreshLiveData();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<DoctorDashboardCubit>().refreshLiveData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DoctorDashboardCubit, DoctorDashboardState>(
          listenWhen: (oldState, newState) =>
              oldState.errorMessage != newState.errorMessage ||
              oldState.notice != newState.notice,
          listener: (context, state) {
            final message = state.errorMessage ?? state.notice;
            if (message == null || message.isEmpty) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(message, textDirection: TextDirection.rtl),
                  backgroundColor: state.errorMessage == null
                      ? _deepTeal
                      : _danger,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            context.read<DoctorDashboardCubit>().clearMessages();
          },
        ),
        BlocListener<UserCubit, UserState>(
          listener: (context, state) {
            if (state is LogoutSuccess) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.welcome, (_) => false);
            }
          },
        ),
      ],
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) SystemNavigator.pop();
        },
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: _background,
            body: BlocBuilder<DoctorDashboardCubit, DoctorDashboardState>(
              builder: (context, state) {
                final firstLoad =
                    state.profile == null &&
                    (state.status == DoctorDashboardStatus.initial ||
                        state.status == DoctorDashboardStatus.loading);
                if (firstLoad) return const _LoadingView();
                if (state.profile == null &&
                    state.status == DoctorDashboardStatus.failure) {
                  return _FailureView(
                    message: state.errorMessage ?? 'تعذر تحميل بيانات الطبيب.',
                    onRetry: () =>
                        context.read<DoctorDashboardCubit>().loadDashboard(),
                  );
                }
                return _selectedPage(state);
              },
            ),
            bottomNavigationBar: _DoctorBottomBar(
              selectedIndex: _selectedIndex,
              onSelected: (index) {
                setState(() => _selectedIndex = index);
                context.read<DoctorDashboardCubit>().refreshLiveData();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectedPage(DoctorDashboardState state) {
    switch (_selectedIndex) {
      case 1:
        return _AppointmentsPage(
          state: state,
          onDetails: _showPatientDetails,
          onStart: _showExamination,
          onNotifications: _openNotifications,
        );
      case 2:
        return _PatientsPage(state: state, onDetails: _showPatientDetails);
      case 3:
        return _RecordsPage(state: state);
      case 4:
        return _AccountPage(state: state);
      default:
        return _Dashboard(
          state: state,
          onSelectTab: (index) => setState(() => _selectedIndex = index),
          onNotifications: _openNotifications,
          onDetails: _showPatientDetails,
          onStart: _showExamination,
          onPrescriptions: () => _openPrescriptions(state.prescriptions),
          onLabs: () => _openLabs(state.medicalRecords),
        );
    }
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<DoctorDashboardCubit>(),
          child: const _NotificationsPage(),
        ),
      ),
    );
  }

  void _openPrescriptions(List<DoctorPrescription> items) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PrescriptionsPage(prescriptions: items),
      ),
    );
  }

  void _openLabs(List<DoctorMedicalRecord> items) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _LaboratoryPage(
          records: items
              .where((record) => record.referredToLaboratory)
              .toList(),
        ),
      ),
    );
  }

  void _showPatientDetails(DoctorAppointment appointment) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PatientDetailsSheet(
        appointment: appointment,
        onStart: () {
          Navigator.pop(context);
          _showExamination(appointment);
        },
      ),
    );
  }

  void _showExamination(DoctorAppointment appointment) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<DoctorDashboardCubit>(),
          child: _VisitCompletionPage(appointment: appointment),
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  final DoctorDashboardState state;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onNotifications;
  final ValueChanged<DoctorAppointment> onDetails;
  final ValueChanged<DoctorAppointment> onStart;
  final VoidCallback onPrescriptions;
  final VoidCallback onLabs;

  const _Dashboard({
    required this.state,
    required this.onSelectTab,
    required this.onNotifications,
    required this.onDetails,
    required this.onStart,
    required this.onPrescriptions,
    required this.onLabs,
  });

  @override
  Widget build(BuildContext context) {
    final today = state.todayAppointments;
    final upcoming = state.upcomingAppointments;
    final next = state.nextAppointment;
    return RefreshIndicator(
      color: _teal,
      onRefresh: () =>
          context.read<DoctorDashboardCubit>().loadDashboard(showLoader: false),
      child: Stack(
        children: [
          const Positioned.fill(child: _DashboardBackground()),
          SafeArea(
            bottom: false,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              children: [
                _Header(
                  profile: state.profile,
                  unreadCount: state.unreadCount,
                  onNotifications: onNotifications,
                ),
                const SizedBox(height: 27),
                _Greeting(profile: state.profile),
                const SizedBox(height: 23),
                _Overview(
                  appointments: today,
                  waiting: state.waitingPatients,
                  notifications: state.unreadCount,
                ),
                if (state.appointmentsError != null) ...[
                  const SizedBox(height: 14),
                  _AppointmentsApiWarning(message: state.appointmentsError!),
                ],
                const SizedBox(height: 27),
                const _TitleWithIcon(
                  title: 'الموعد التالي',
                  icon: Icons.calendar_month_outlined,
                ),
                const SizedBox(height: 10),
                _NextAppointmentCard(
                  appointment: next,
                  onDetails: next == null ? null : () => onDetails(next),
                  onStart: next == null ? null : () => onStart(next),
                ),
                const SizedBox(height: 28),
                const Text(
                  'إجراءات سريعة',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 11),
                _QuickActions(
                  onAppointments: () => onSelectTab(1),
                  onRecords: () => onSelectTab(3),
                  onPrescriptions: onPrescriptions,
                  onLabs: onLabs,
                ),
                const SizedBox(height: 27),
                _SectionHeading(
                  title: 'المواعيد القادمة',
                  action: 'عرض الكل',
                  onAction: () => onSelectTab(1),
                ),
                const SizedBox(height: 10),
                _UpcomingCard(
                  appointments: upcoming.take(3).toList(),
                  onTap: onDetails,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardBackground extends StatelessWidget {
  const _DashboardBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _BackgroundPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wash = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF9FCFE), Color(0xFFF1F9FC), Color(0xFFF9FCFD)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, wash);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF77C5CF).withAlpha(40);
    canvas.drawCircle(Offset(size.width * .34, 170), 128, ring);
    canvas.drawCircle(Offset(size.width * .34, 170), 170, ring);
    canvas.drawCircle(Offset(size.width * .1, size.height * .48), 75, ring);
    canvas.drawCircle(Offset(size.width * .94, size.height * .38), 60, ring);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Header extends StatelessWidget {
  final DoctorDashboardProfile? profile;
  final int unreadCount;
  final VoidCallback onNotifications;

  const _Header({
    required this.profile,
    required this.unreadCount,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: onNotifications,
              tooltip: 'التنبيهات',
              iconSize: 31,
              color: const Color(0xFF3A444B),
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                backgroundColor: _teal,
                label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
                child: const Icon(Icons.notifications_none_rounded),
              ),
            ),
          ),
          Image.asset(
            'assets/images/logo.png',
            width: 74,
            height: 48,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Text(
              'نبض',
              style: TextStyle(
                color: _teal,
                fontSize: 35,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _Avatar(
              imageUrl: profile?.profileImage,
              name: profile?.fullName ?? '',
              size: 58,
              borderWidth: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final DoctorDashboardProfile? profile;

  const _Greeting({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'مرحباً د. ',
                style: TextStyle(color: _ink),
              ),
              TextSpan(
                text: profile?.fullName ?? 'الطبيب',
                style: const TextStyle(color: _teal),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'إليك نظرة سريعة على يومك الطبي',
          style: TextStyle(
            color: _muted,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _Overview extends StatelessWidget {
  final List<DoctorAppointment> appointments;
  final int waiting;
  final int notifications;

  const _Overview({
    required this.appointments,
    required this.waiting,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.calendar_today_outlined,
            value: '${appointments.length}',
            title: 'مواعيد اليوم',
            subtitle: _workingHours(appointments),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            icon: Icons.people_alt_outlined,
            value: '$waiting',
            title: 'مرضى بانتظارك',
            subtitle: waiting == 0 ? 'لا يوجد انتظار' : 'في العيادة',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            icon: Icons.notifications_none_rounded,
            value: '$notifications',
            title: 'تنبيهات جديدة',
            subtitle: notifications == 0 ? 'لا تنبيهات' : 'تحتاج إلى انتباه',
            danger: notifications > 0,
          ),
        ),
      ],
    );
  }

  String _workingHours(List<DoctorAppointment> values) {
    if (values.isEmpty) return 'لا مواعيد اليوم';
    final sorted = [...values]
      ..sort(
        (a, b) => (a.dateTime ?? DateTime(2100)).compareTo(
          b.dateTime ?? DateTime(2100),
        ),
      );
    return 'من ${_displayTime(sorted.first.time)} إلى ${_displayTime(sorted.last.time)}';
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String title;
  final String subtitle;
  final bool danger;

  const _MetricCard({
    required this.icon,
    required this.value,
    required this.title,
    required this.subtitle,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = danger ? _danger : _deepTeal;
    return Container(
      height: 145,
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120C6570),
            blurRadius: 23,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: danger
                      ? const Color(0xFFFFE7E9)
                      : const Color(0xFFE4F5F7),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 23),
              ),
              Text(
                value,
                style: TextStyle(
                  color: accent,
                  fontSize: 28,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 10.5),
          ),
        ],
      ),
    );
  }
}

class _TitleWithIcon extends StatelessWidget {
  final String title;
  final IconData icon;

  const _TitleWithIcon({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(icon, color: _teal, size: 23),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _deepTeal,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _NextAppointmentCard extends StatelessWidget {
  final DoctorAppointment? appointment;
  final VoidCallback? onDetails;
  final VoidCallback? onStart;

  const _NextAppointmentCard({
    required this.appointment,
    required this.onDetails,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    if (appointment == null) {
      return Container(
        height: 176,
        decoration: _heroDecoration(),
        child: const _EmptyState(
          icon: Icons.event_available_outlined,
          message: 'لا يوجد موعد قادم حالياً',
          light: true,
        ),
      );
    }
    final item = appointment!;
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 20, 17, 17),
      decoration: _heroDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              _Avatar(
                imageUrl: item.patientImage,
                name: item.patientName,
                size: 76,
                borderWidth: 3,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.patientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.visitType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFC8EBEE),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.notes.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.notes,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFC8EBEE),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 73,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: Colors.white.withAlpha(65),
              ),
              SizedBox(
                width: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _displayTime(item.time),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: Color(0xFFC8EBEE),
                          size: 17,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${item.durationMinutes} دقيقة',
                            style: const TextStyle(
                              color: Color(0xFFC8EBEE),
                              fontSize: 11.5,
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
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                flex: 11,
                child: FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.medical_services_outlined, size: 21),
                  label: const Text('بدء المعاينة'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _deepTeal,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                flex: 10,
                child: OutlinedButton.icon(
                  onPressed: onDetails,
                  icon: const Icon(Icons.person_outline_rounded, size: 20),
                  label: const Text('تفاصيل المريض'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withAlpha(145)),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _heroDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF07929E), Color(0xFF006B75)],
      ),
      borderRadius: BorderRadius.circular(26),
      boxShadow: const [
        BoxShadow(
          color: Color(0x25006670),
          blurRadius: 25,
          offset: Offset(0, 13),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onAppointments;
  final VoidCallback onRecords;
  final VoidCallback onPrescriptions;
  final VoidCallback onLabs;

  const _QuickActions({
    required this.onAppointments,
    required this.onRecords,
    required this.onPrescriptions,
    required this.onLabs,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.calendar_today_outlined, 'مواعيدي', onAppointments),
      (Icons.description_outlined, 'السجلات', onRecords),
      (Icons.medication_outlined, 'الوصفات', onPrescriptions),
      (Icons.science_outlined, 'التحاليل', onLabs),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 6),
      decoration: _whiteCardDecoration(25),
      child: Row(
        children: List.generate(actions.length, (index) {
          final action = actions[index];
          return Expanded(
            child: Row(
              children: [
                if (index > 0)
                  Container(
                    width: 1,
                    height: 52,
                    color: const Color(0xFFE1EAED),
                  ),
                Expanded(
                  child: InkWell(
                    onTap: action.$3,
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: _paleTeal,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(action.$1, color: _teal, size: 27),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          action.$2,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onAction;

  const _SectionHeading({
    required this.title,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onAction,
          label: Text(action),
          icon: const Icon(Icons.chevron_left_rounded, size: 21),
          style: TextButton.styleFrom(
            foregroundColor: _teal,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final List<DoctorAppointment> appointments;
  final ValueChanged<DoctorAppointment> onTap;

  const _UpcomingCard({required this.appointments, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      decoration: _whiteCardDecoration(25),
      child: appointments.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: _EmptyState(
                icon: Icons.event_available_outlined,
                message: 'لا توجد مواعيد قادمة',
              ),
            )
          : Column(
              children: List.generate(appointments.length, (index) {
                final item = appointments[index];
                return Column(
                  children: [
                    _CompactAppointment(
                      appointment: item,
                      onTap: () => onTap(item),
                    ),
                    if (index < appointments.length - 1)
                      const Divider(height: 1, color: Color(0xFFE4ECEF)),
                  ],
                );
              }),
            ),
    );
  }
}

class _CompactAppointment extends StatelessWidget {
  final DoctorAppointment appointment;
  final VoidCallback onTap;

  const _CompactAppointment({required this.appointment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            const Icon(Icons.chevron_left_rounded, color: _teal, size: 24),
            _StatusChip(status: appointment.status),
            const SizedBox(width: 9),
            _Avatar(
              imageUrl: appointment.patientImage,
              name: appointment.patientName,
              size: 47,
              borderWidth: 0,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.patientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    appointment.visitType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _displayTime(appointment.time),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${appointment.durationMinutes} دقيقة',
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final confirmed = status == 'confirmed' || status == 'checked_in';
    final pending = status == 'pending' || status == 'waiting';
    final color = confirmed
        ? const Color(0xFF20894C)
        : pending
        ? const Color(0xFFB56B08)
        : _muted;
    final background = confirmed
        ? const Color(0xFFE4F5E9)
        : pending
        ? const Color(0xFFFFF3D8)
        : const Color(0xFFEAF0F2);
    final label = confirmed
        ? 'مؤكد'
        : pending
        ? 'انتظار'
        : _statusLabel(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentsPage extends StatefulWidget {
  final DoctorDashboardState state;
  final ValueChanged<DoctorAppointment> onDetails;
  final ValueChanged<DoctorAppointment> onStart;
  final VoidCallback onNotifications;

  const _AppointmentsPage({
    required this.state,
    required this.onDetails,
    required this.onStart,
    required this.onNotifications,
  });

  @override
  State<_AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<_AppointmentsPage> {
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final selectedAppointments =
        state.appointments.where((item) {
          final date = item.dateTime;
          if (_filter == 1) {
            return date != null &&
                !item.isFinished &&
                !date.isBefore(DateTime.now());
          }
          if (_filter == 2) return item.isFinished;
          return date != null && DateUtils.isSameDay(date, _selectedDate);
        }).toList()..sort(
          (a, b) => (a.dateTime ?? DateTime(2100)).compareTo(
            b.dateTime ?? DateTime(2100),
          ),
        );
    final dayAppointments = state.appointments
        .where(
          (item) =>
              item.dateTime != null &&
              DateUtils.isSameDay(item.dateTime, _selectedDate),
        )
        .toList();
    final confirmed = dayAppointments
        .where(
          (item) => item.status == 'confirmed' || item.status == 'checked_in',
        )
        .length;
    final waiting = dayAppointments.where((item) => item.isWaiting).length;
    final next = selectedAppointments
        .where((item) => !item.isFinished)
        .cast<DoctorAppointment?>()
        .firstOrNull;

    return RefreshIndicator(
      color: _teal,
      onRefresh: () =>
          context.read<DoctorDashboardCubit>().loadDashboard(showLoader: false),
      child: Stack(
        children: [
          const Positioned.fill(child: _DashboardBackground()),
          SafeArea(
            bottom: false,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              children: [
                _Header(
                  profile: state.profile,
                  unreadCount: state.unreadCount,
                  onNotifications: widget.onNotifications,
                ),
                const SizedBox(height: 23),
                const Text(
                  'مواعيدي',
                  style: TextStyle(
                    color: _teal,
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'جدول اليوم وجميع المراجعين',
                  style: TextStyle(color: _muted, fontSize: 15),
                ),
                const SizedBox(height: 22),
                _DateStrip(
                  selectedDate: _selectedDate,
                  onSelected: (date) => setState(() => _selectedDate = date),
                  onPrevious: () => setState(
                    () => _selectedDate = _selectedDate.subtract(
                      const Duration(days: 5),
                    ),
                  ),
                  onNext: () => setState(
                    () => _selectedDate = _selectedDate.add(
                      const Duration(days: 5),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                _AppointmentFilters(
                  selected: _filter,
                  onSelected: (value) => setState(() => _filter = value),
                ),
                const SizedBox(height: 18),
                _AppointmentSummary(
                  total: dayAppointments.length,
                  confirmed: confirmed,
                  waiting: waiting,
                ),
                if (state.appointmentsError != null) ...[
                  const SizedBox(height: 14),
                  _AppointmentsApiWarning(message: state.appointmentsError!),
                ],
                if (next != null) ...[
                  const SizedBox(height: 22),
                  const Text(
                    'الزيارة التالية',
                    style: TextStyle(
                      color: _deepTeal,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),
                  _NextAppointmentCard(
                    appointment: next,
                    onDetails: () => widget.onDetails(next),
                    onStart: () => widget.onStart(next),
                  ),
                ],
                const SizedBox(height: 23),
                Text(
                  _filter == 0 ? 'جدول مواعيد اليوم' : 'قائمة المواعيد',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                if (selectedAppointments.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 35),
                    decoration: _whiteCardDecoration(24),
                    child: _EmptyState(
                      icon: Icons.event_busy_outlined,
                      message: state.appointmentsError == null
                          ? 'لا توجد مواعيد ضمن هذا التصنيف'
                          : 'تعذر جلب المواعيد من الخادم',
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: _whiteCardDecoration(24),
                    child: Column(
                      children: List.generate(selectedAppointments.length, (
                        index,
                      ) {
                        final item = selectedAppointments[index];
                        return Column(
                          children: [
                            _CompactAppointment(
                              appointment: item,
                              onTap: () => widget.onDetails(item),
                            ),
                            if (index < selectedAppointments.length - 1)
                              const Divider(
                                height: 1,
                                color: Color(0xFFE4ECEF),
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateStrip extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _DateStrip({
    required this.selectedDate,
    required this.onSelected,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final days = List.generate(
      5,
      (index) => selectedDate.add(Duration(days: index - 2)),
    );
    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_right_rounded, color: _teal),
        ),
        Expanded(
          child: Row(
            children: days.map((date) {
              final selected = DateUtils.isSameDay(date, selectedDate);
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelected(DateUtils.dateOnly(date)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: selected ? 109 : 103,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? _teal : Colors.white,
                      borderRadius: BorderRadius.circular(19),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x100C6570),
                          blurRadius: 15,
                          offset: Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _arabicWeekday(date.weekday),
                          maxLines: 1,
                          style: TextStyle(
                            color: selected ? Colors.white : _ink,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: selected ? Colors.white : _ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _arabicMonth(date.month),
                          style: TextStyle(
                            color: selected ? Colors.white : _muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_left_rounded, color: _teal),
        ),
      ],
    );
  }
}

class _AppointmentFilters extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _AppointmentFilters({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.calendar_today_outlined, 'اليوم'),
      (Icons.schedule_outlined, 'القادمة'),
      (Icons.check_circle_outline_rounded, 'المكتملة'),
    ];
    return Row(
      children: List.generate(items.length, (index) {
        final active = selected == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 50,
              margin: EdgeInsetsDirectional.only(end: index < 2 ? 8 : 0),
              decoration: BoxDecoration(
                color: active ? _teal : const Color(0xFFF0F6F7),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    items[index].$1,
                    color: active ? Colors.white : _muted,
                    size: 19,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      items[index].$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active ? Colors.white : _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _AppointmentSummary extends StatelessWidget {
  final int total;
  final int confirmed;
  final int waiting;

  const _AppointmentSummary({
    required this.total,
    required this.confirmed,
    required this.waiting,
  });

  @override
  Widget build(BuildContext context) {
    final values = [
      (Icons.calendar_today_outlined, 'إجمالي المواعيد', total, _teal),
      (Icons.how_to_reg_outlined, 'مؤكدة', confirmed, const Color(0xFF258C4A)),
      (
        Icons.person_pin_circle_outlined,
        'بانتظار الوصول',
        waiting,
        const Color(0xFFE77A0B),
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: _whiteCardDecoration(23),
      child: Row(
        children: List.generate(values.length, (index) {
          final item = values[index];
          return Expanded(
            child: Container(
              decoration: index == values.length - 1
                  ? null
                  : const BoxDecoration(
                      border: BorderDirectional(
                        end: BorderSide(color: Color(0xFFE0E9EC)),
                      ),
                    ),
              child: Column(
                children: [
                  Icon(item.$1, color: item.$4, size: 25),
                  const SizedBox(height: 6),
                  Text(
                    item.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _ink, fontSize: 11.5),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.$3}',
                    style: TextStyle(
                      color: item.$4,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _AppointmentsApiWarning extends StatelessWidget {
  final String message;

  const _AppointmentsApiWarning({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E2),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0x55E77A0B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFE77A0B)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _ink, fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

// Kept as a compact fallback while the richer schedule view is active.
// ignore: unused_element
class _LegacyAppointmentsPage extends StatelessWidget {
  final DoctorDashboardState state;
  final ValueChanged<DoctorAppointment> onDetails;
  final ValueChanged<DoctorAppointment> onStart;

  const _LegacyAppointmentsPage({
    required this.state,
    required this.onDetails,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return _StandardPage(
      title: 'مواعيدي',
      subtitle: '${state.appointments.length} موعد',
      onRefresh: () =>
          context.read<DoctorDashboardCubit>().loadDashboard(showLoader: false),
      child: state.appointments.isEmpty
          ? const _LargeEmptyState(
              icon: Icons.calendar_month_outlined,
              message: 'لا توجد مواعيد لعرضها',
            )
          : Column(
              children: state.appointments.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 11),
                  decoration: _whiteCardDecoration(22),
                  child: InkWell(
                    onTap: () => onDetails(item),
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _Avatar(
                                imageUrl: item.patientImage,
                                name: item.patientName,
                                size: 57,
                                borderWidth: 0,
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.patientName,
                                      style: const TextStyle(
                                        color: _ink,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '${item.visitType} • ${_formatDate(item.date)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _displayTime(item.time),
                                    textDirection: TextDirection.ltr,
                                    style: const TextStyle(
                                      color: _deepTeal,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  _StatusChip(status: item.status),
                                ],
                              ),
                            ],
                          ),
                          if (!item.isFinished) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => onStart(item),
                                icon: const Icon(
                                  Icons.medical_services_outlined,
                                  size: 19,
                                ),
                                label: const Text('بدء المعاينة'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: _teal,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _PatientsPage extends StatelessWidget {
  final DoctorDashboardState state;
  final ValueChanged<DoctorAppointment> onDetails;

  const _PatientsPage({required this.state, required this.onDetails});

  @override
  Widget build(BuildContext context) {
    final patients = <int, DoctorAppointment>{};
    for (final item in state.appointments) {
      final key = item.patientId != 0
          ? item.patientId
          : item.patientName.hashCode;
      patients[key] = item;
    }
    return _StandardPage(
      title: 'مرضاي',
      subtitle: '${patients.length} مريض',
      onRefresh: () =>
          context.read<DoctorDashboardCubit>().loadDashboard(showLoader: false),
      child: patients.isEmpty
          ? Column(
              children: [
                if (state.appointmentsError != null) ...[
                  _AppointmentsApiWarning(message: state.appointmentsError!),
                  const SizedBox(height: 12),
                ],
                const _LargeEmptyState(
                  icon: Icons.groups_outlined,
                  message: 'لا توجد بيانات مرضى حالياً',
                ),
              ],
            )
          : Column(
              children: patients.values.map((patient) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: _whiteCardDecoration(21),
                  child: ListTile(
                    onTap: () => onDetails(patient),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    leading: _Avatar(
                      imageUrl: patient.patientImage,
                      name: patient.patientName,
                      size: 52,
                      borderWidth: 0,
                    ),
                    title: Text(
                      patient.patientName,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      patient.phone.isEmpty ? patient.visitType : patient.phone,
                      style: const TextStyle(color: _muted),
                    ),
                    trailing: const Icon(
                      Icons.chevron_left_rounded,
                      color: _teal,
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _RecordsPage extends StatelessWidget {
  final DoctorDashboardState state;

  const _RecordsPage({required this.state});

  @override
  Widget build(BuildContext context) {
    return _StandardPage(
      title: 'السجل الطبي',
      subtitle: '${state.medicalRecords.length} سجل',
      onRefresh: () =>
          context.read<DoctorDashboardCubit>().loadDashboard(showLoader: false),
      child: state.medicalRecords.isEmpty
          ? const _LargeEmptyState(
              icon: Icons.folder_open_outlined,
              message: 'لا توجد سجلات طبية حالياً',
            )
          : Column(
              children: state.medicalRecords
                  .map((record) => _RecordCard(record: record))
                  .toList(),
            ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final DoctorMedicalRecord record;

  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _MedicalRecordDetailsPage(record: record),
        ),
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: _whiteCardDecoration(21),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: _paleTeal,
              foregroundColor: _teal,
              child: Icon(Icons.description_outlined),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.patientName,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    record.diagnosis,
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                  if (record.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      record.notes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              _formatDate(record.date),
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicalRecordDetailsPage extends StatefulWidget {
  final DoctorMedicalRecord record;

  const _MedicalRecordDetailsPage({required this.record});

  @override
  State<_MedicalRecordDetailsPage> createState() =>
      _MedicalRecordDetailsPageState();
}

class _MedicalRecordDetailsPageState extends State<_MedicalRecordDetailsPage> {
  late DoctorMedicalRecord _record;
  late final TextEditingController _diagnosis;
  late final TextEditingController _diseases;
  late final TextEditingController _bloodType;
  late final TextEditingController _heartRate;
  late final TextEditingController _allergies;
  late final TextEditingController _notes;
  late final TextEditingController _laboratoryNotes;
  late bool _referToPharmacist;
  late bool _referToLaboratory;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _record = widget.record;
    _diagnosis = TextEditingController(text: _record.diagnosis);
    _diseases = TextEditingController(text: _record.diseases);
    _bloodType = TextEditingController(text: _record.bloodType);
    _heartRate = TextEditingController(
      text: _record.heartRate?.toString() ?? '',
    );
    _allergies = TextEditingController(text: _record.allergies);
    _notes = TextEditingController(text: _record.notes);
    _laboratoryNotes = TextEditingController(text: _record.laboratoryNotes);
    _referToPharmacist = _record.referredToPharmacist;
    _referToLaboratory = _record.referredToLaboratory;
  }

  @override
  void dispose() {
    _diagnosis.dispose();
    _diseases.dispose();
    _bloodType.dispose();
    _heartRate.dispose();
    _allergies.dispose();
    _notes.dispose();
    _laboratoryNotes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DoctorDashboardCubit, DoctorDashboardState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: _background,
          appBar: AppBar(
            title: const Text('تفاصيل السجل الطبي'),
            actions: [
              IconButton(
                tooltip: _editing ? 'إلغاء التعديل' : 'تعديل',
                onPressed: state.actionLoading
                    ? null
                    : () => setState(() => _editing = !_editing),
                icon: Icon(
                  _editing ? Icons.close_rounded : Icons.edit_outlined,
                ),
              ),
              IconButton(
                tooltip: 'حذف',
                onPressed: state.actionLoading ? null : _confirmDelete,
                icon: const Icon(Icons.delete_outline_rounded, color: _danger),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: _whiteCardDecoration(22),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: _paleTeal,
                        foregroundColor: _teal,
                        child: Icon(Icons.person_outline_rounded, size: 30),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _record.patientName,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'تاريخ السجل: ${_formatDate(_record.date)}',
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _recordField('التشخيص', _diagnosis, required: true),
                _recordField('الأمراض المزمنة', _diseases),
                Row(
                  children: [
                    Expanded(child: _recordField('فصيلة الدم', _bloodType)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _recordField(
                        'نبض القلب',
                        _heartRate,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                _recordField('الحساسيات', _allergies),
                _recordField('ملاحظات الطبيب', _notes, maxLines: 3),
                _recordSwitch(
                  title: 'إحالة إلى الصيدلية',
                  value: _referToPharmacist,
                  onChanged: (value) =>
                      setState(() => _referToPharmacist = value),
                ),
                _recordSwitch(
                  title: 'إحالة إلى المختبر',
                  value: _referToLaboratory,
                  onChanged: (value) =>
                      setState(() => _referToLaboratory = value),
                ),
                if (_referToLaboratory)
                  _recordField(
                    'ملاحظات المختبر',
                    _laboratoryNotes,
                    maxLines: 3,
                  ),
                if (_record.laboratoryStatus.isNotEmpty && !_editing)
                  ListTile(
                    leading: const Icon(Icons.science_outlined, color: _teal),
                    title: const Text('حالة طلب المختبر'),
                    trailing: Text(_record.laboratoryStatus),
                  ),
                if (_editing) ...[
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: state.actionLoading ? null : _save,
                    icon: state.actionLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('حفظ التعديلات'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _teal,
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _recordField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: TextFormField(
        controller: controller,
        readOnly: !_editing,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          filled: true,
          fillColor: _editing ? Colors.white : const Color(0xFFF4F8F8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  Widget _recordSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      activeThumbColor: _teal,
      onChanged: _editing ? onChanged : null,
    );
  }

  Future<void> _save() async {
    if (_diagnosis.text.trim().isEmpty) {
      _message('يرجى إدخال التشخيص.');
      return;
    }
    final heartRateText = _heartRate.text.trim();
    final heartRate = heartRateText.isEmpty
        ? null
        : int.tryParse(heartRateText);
    if (heartRateText.isNotEmpty && heartRate == null) {
      _message('نبض القلب يجب أن يكون رقماً صحيحاً.');
      return;
    }
    final success = await context
        .read<DoctorDashboardCubit>()
        .updateMedicalRecord(_record.id, {
          'diagnosis': _diagnosis.text.trim(),
          'diseases': _diseases.text.trim(),
          'blood_type': _bloodType.text.trim(),
          if (heartRate != null) 'heart_rate': heartRate,
          'allergies': _allergies.text.trim(),
          'notes': _notes.text.trim(),
          'refer_to_pharmacist': _referToPharmacist,
          'refer_to_laboratory': _referToLaboratory,
          'laboratory_notes': _laboratoryNotes.text.trim(),
        });
    if (!mounted) return;
    if (success) {
      setState(() {
        _record = _record.copyWith(
          diagnosis: _diagnosis.text.trim(),
          diseases: _diseases.text.trim(),
          bloodType: _bloodType.text.trim(),
          heartRate: heartRate,
          allergies: _allergies.text.trim(),
          notes: _notes.text.trim(),
          referredToPharmacist: _referToPharmacist,
          referredToLaboratory: _referToLaboratory,
          laboratoryNotes: _laboratoryNotes.text.trim(),
        );
        _editing = false;
      });
      _message('تم حفظ التعديلات.');
    } else {
      _message(
        context.read<DoctorDashboardCubit>().state.errorMessage ??
            'تعذر تعديل السجل.',
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف السجل الطبي؟'),
        content: const Text(
          'سيتم حذف السجل نهائياً ولا يمكن التراجع عن هذه العملية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await context
        .read<DoctorDashboardCubit>()
        .deleteMedicalRecord(_record.id);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      _message(
        context.read<DoctorDashboardCubit>().state.errorMessage ??
            'تعذر حذف السجل.',
      );
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AccountPage extends StatelessWidget {
  final DoctorDashboardState state;

  const _AccountPage({required this.state});

  @override
  Widget build(BuildContext context) {
    final profile = state.profile;
    return _StandardPage(
      title: 'حسابي',
      subtitle: profile?.specialization ?? '',
      onRefresh: () =>
          context.read<DoctorDashboardCubit>().loadDashboard(showLoader: false),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: _whiteCardDecoration(25),
            child: Column(
              children: [
                _Avatar(
                  imageUrl: profile?.profileImage,
                  name: profile?.fullName ?? '',
                  size: 92,
                  borderWidth: 3,
                ),
                const SizedBox(height: 13),
                Text(
                  'د. ${profile?.fullName ?? 'الطبيب'}',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile?.specialization ?? '',
                  style: const TextStyle(color: _teal, fontSize: 14),
                ),
                const SizedBox(height: 20),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'رقم الهاتف',
                  value: profile?.phone ?? '',
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'البريد الإلكتروني',
                  value: profile?.email ?? '',
                ),
              ],
            ),
          ),
          const SizedBox(height: 17),
          Container(
            decoration: _whiteCardDecoration(20),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 6,
              ),
              leading: const CircleAvatar(
                backgroundColor: _paleTeal,
                foregroundColor: _teal,
                child: Icon(Icons.calendar_month_outlined),
              ),
              title: const Text(
                'جدول الدوام',
                style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('ساعات العمل والأيام المتاحة'),
              trailing: const Icon(Icons.chevron_left_rounded, color: _teal),
              onTap: profile == null || profile.doctorId == 0
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            _DoctorSchedulePage(doctorId: profile.doctorId),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: _whiteCardDecoration(20),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 6,
              ),
              leading: const CircleAvatar(
                backgroundColor: _paleTeal,
                foregroundColor: _teal,
                child: Icon(Icons.account_balance_wallet_outlined),
              ),
              title: const Text(
                'محفظتي',
                style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('عرض الرصيد وسجل الحركات'),
              trailing: const Icon(Icons.chevron_left_rounded, color: _teal),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const WalletScreen(
                    title: 'محفظة الدكتور',
                    allowTopUp: false,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 17),
          BlocBuilder<UserCubit, UserState>(
            builder: (context, userState) {
              final loading = userState is LogoutLoading;
              return SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: loading
                      ? null
                      : () => context.read<UserCubit>().logout(),
                  icon: loading
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout_rounded),
                  label: const Text('تسجيل الخروج'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _danger,
                    side: const BorderSide(color: Color(0x33C91F2A)),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DoctorSchedulePage extends StatefulWidget {
  final int doctorId;

  const _DoctorSchedulePage({required this.doctorId});

  @override
  State<_DoctorSchedulePage> createState() => _DoctorSchedulePageState();
}

class _DoctorSchedulePageState extends State<_DoctorSchedulePage> {
  List<DoctorScheduleModel> _schedule = const [];
  List<DoctorAvailableDateModel> _dates = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final now = DateTime.now();
    try {
      final results = await Future.wait<dynamic>([
        context.read<AppointmentCubit>().getDoctorSchedule(widget.doctorId),
        context.read<AppointmentCubit>().getDoctorAvailableDates(
          doctorId: widget.doctorId,
          from: now,
          to: now.add(const Duration(days: 13)),
        ),
      ]);
      if (!mounted) return;
      final schedule = [...results[0] as List<DoctorScheduleModel>]
        ..sort((a, b) => _dayOrder(a.day).compareTo(_dayOrder(b.day)));
      setState(() {
        _schedule = schedule;
        _dates = results[1] as List<DoctorAvailableDateModel>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تحميل جدول الدوام. حاول مجدداً.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          title: const Text('جدول الدوام'),
          backgroundColor: _background,
          surfaceTintColor: Colors.transparent,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _FailureView(message: _error!, onRetry: _load)
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: _paleTeal,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: _teal),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'تعديل الدوام والإجازات يتم من لوحة الإدارة.',
                              style: TextStyle(
                                color: _deepTeal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'البرنامج الأسبوعي',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_schedule.isEmpty)
                      const _EmptyState(
                        icon: Icons.event_busy_outlined,
                        message: 'لم يتم تحديد جدول دوام بعد',
                      )
                    else
                      ..._schedule.map(
                        (item) => Container(
                          margin: const EdgeInsets.only(bottom: 9),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: _whiteCardDecoration(18),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: _paleTeal,
                                foregroundColor: _teal,
                                child: Icon(Icons.schedule_rounded),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _arabicDay(item.day),
                                  style: const TextStyle(
                                    color: _ink,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                '${_shortTime(item.startTime)} – ${_shortTime(item.endTime)}',
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  color: _teal,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    const Text(
                      'التوفر خلال الأسبوعين القادمين',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._dates.map((item) {
                      final available = item.isAvailable;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        leading: Icon(
                          available
                              ? Icons.event_available_rounded
                              : Icons.event_busy_rounded,
                          color: available ? _teal : _danger,
                        ),
                        title: Text(
                          '${_arabicWeekday(item.date.weekday)}، ${item.date.day}/${item.date.month}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        trailing: Text(
                          available
                              ? '${item.availableSlots} موعد متاح'
                              : 'غير متاح',
                          style: TextStyle(
                            color: available ? _teal : _danger,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
      ),
    );
  }

  int _dayOrder(String day) =>
      const {
        'Saturday': 1,
        'Sunday': 2,
        'Monday': 3,
        'Tuesday': 4,
        'Wednesday': 5,
        'Thursday': 6,
        'Friday': 7,
      }[day] ??
      8;

  String _arabicDay(String day) =>
      const {
        'Saturday': 'السبت',
        'Sunday': 'الأحد',
        'Monday': 'الاثنين',
        'Tuesday': 'الثلاثاء',
        'Wednesday': 'الأربعاء',
        'Thursday': 'الخميس',
        'Friday': 'الجمعة',
      }[day] ??
      day;

  String _arabicWeekday(int day) =>
      const {
        1: 'الاثنين',
        2: 'الثلاثاء',
        3: 'الأربعاء',
        4: 'الخميس',
        5: 'الجمعة',
        6: 'السبت',
        7: 'الأحد',
      }[day] ??
      '';

  String _shortTime(String value) =>
      value.length >= 5 ? value.substring(0, 5) : value;
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _teal),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: _muted, fontSize: 11.5),
              ),
              const SizedBox(height: 3),
              Text(
                value.isEmpty ? 'غير متوفر' : value,
                style: const TextStyle(color: _ink, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StandardPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final Future<void> Function() onRefresh;
  final Widget child;

  const _StandardPage({
    required this.title,
    required this.subtitle,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _teal,
      onRefresh: onRefresh,
      child: SafeArea(
        bottom: false,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _ink,
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(subtitle, style: const TextStyle(color: _muted, fontSize: 14)),
            const SizedBox(height: 23),
            child,
          ],
        ),
      ),
    );
  }
}

class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          title: const Text('التنبيهات'),
          backgroundColor: _background,
          surfaceTintColor: Colors.transparent,
          actions: [
            BlocBuilder<DoctorDashboardCubit, DoctorDashboardState>(
              builder: (context, state) => TextButton(
                onPressed: state.unreadCount == 0
                    ? null
                    : () => context
                          .read<DoctorDashboardCubit>()
                          .markAllNotificationsRead(),
                child: const Text('قراءة الكل'),
              ),
            ),
          ],
        ),
        body: BlocBuilder<DoctorDashboardCubit, DoctorDashboardState>(
          builder: (context, state) {
            if (state.notifications.isEmpty) {
              return const _LargeEmptyState(
                icon: Icons.notifications_none_rounded,
                message: 'لا توجد تنبيهات حالياً',
              );
            }
            return RefreshIndicator(
              color: _teal,
              onRefresh: () => context
                  .read<DoctorDashboardCubit>()
                  .loadDashboard(showLoader: false),
              child: ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: state.notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = state.notifications[index];
                  return Material(
                    color: item.isRead ? Colors.white : const Color(0xFFE9F7F8),
                    borderRadius: BorderRadius.circular(20),
                    child: ListTile(
                      onTap: item.isRead
                          ? null
                          : () => context
                                .read<DoctorDashboardCubit>()
                                .markNotificationRead(item.id),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 8,
                      ),
                      leading: const CircleAvatar(
                        radius: 23,
                        backgroundColor: _paleTeal,
                        foregroundColor: _teal,
                        child: Icon(Icons.notifications_outlined),
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          item.body,
                          style: const TextStyle(color: _muted),
                        ),
                      ),
                      trailing: item.isRead
                          ? null
                          : Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: _teal,
                                shape: BoxShape.circle,
                              ),
                            ),
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

class _PrescriptionsPage extends StatelessWidget {
  final List<DoctorPrescription> prescriptions;

  const _PrescriptionsPage({required this.prescriptions});

  @override
  Widget build(BuildContext context) {
    return _ListScaffold(
      title: 'الوصفات الطبية',
      isEmpty: prescriptions.isEmpty,
      emptyIcon: Icons.medication_outlined,
      emptyMessage: 'لا توجد وصفات طبية حالياً',
      itemCount: prescriptions.length,
      itemBuilder: (context, index) {
        final item = prescriptions[index];
        return _SimpleDataCard(
          icon: Icons.medication_outlined,
          title: item.patientName,
          subtitle: item.instructions.isEmpty
              ? '${item.itemsCount} أدوية'
              : item.instructions,
          trailing: _formatDate(item.date),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _PrescriptionDetailsPage(summary: item),
            ),
          ),
        );
      },
    );
  }
}

class _PrescriptionDetailsPage extends StatefulWidget {
  final DoctorPrescription summary;

  const _PrescriptionDetailsPage({required this.summary});

  @override
  State<_PrescriptionDetailsPage> createState() =>
      _PrescriptionDetailsPageState();
}

class _PrescriptionDetailsPageState extends State<_PrescriptionDetailsPage> {
  DoctorPrescription? _prescription;
  final _instructions = TextEditingController();
  final _notes = TextEditingController();
  List<VisitMedicineInput> _items = [];
  bool _loading = true;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _instructions.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await context
        .read<DoctorDashboardCubit>()
        .loadPrescriptionDetails(widget.summary.id);
    if (!mounted) return;
    setState(() {
      _prescription = result;
      _instructions.text = result?.instructions ?? '';
      _notes.text = result?.notes ?? '';
      _items = [...?result?.items];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final prescription = _prescription;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          title: const Text('تفاصيل الوصفة'),
          backgroundColor: _background,
          surfaceTintColor: Colors.transparent,
          actions: prescription == null
              ? null
              : [
                  if (prescription.status == 'pending')
                    IconButton(
                      tooltip: _editing ? 'إلغاء التعديل' : 'تعديل الوصفة',
                      onPressed: () => setState(() => _editing = !_editing),
                      icon: Icon(
                        _editing ? Icons.close_rounded : Icons.edit_outlined,
                      ),
                    ),
                  IconButton(
                    tooltip: 'حذف الوصفة',
                    onPressed: _confirmDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: _danger,
                    ),
                  ),
                ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : prescription == null
            ? _FailureView(
                message:
                    context.read<DoctorDashboardCubit>().state.errorMessage ??
                    'تعذر تحميل تفاصيل الوصفة.',
                onRetry: _load,
              )
            : BlocBuilder<DoctorDashboardCubit, DoctorDashboardState>(
                builder: (context, state) => ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: _whiteCardDecoration(22),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 27,
                            backgroundColor: _paleTeal,
                            foregroundColor: _teal,
                            child: Icon(Icons.medication_outlined, size: 29),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            prescription.patientName,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'الحالة: ${_prescriptionStatus(prescription.status)}',
                            style: const TextStyle(
                              color: _teal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (prescription.date.isNotEmpty)
                            Text(
                              'تاريخ الإصدار: ${_formatDate(prescription.date)}',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _prescriptionField('التعليمات', _instructions, maxLines: 3),
                    _prescriptionField('ملاحظات', _notes, maxLines: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الأدوية',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (_editing)
                          TextButton.icon(
                            onPressed: _addMedicine,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('إضافة دواء'),
                          ),
                      ],
                    ),
                    if (_items.isEmpty)
                      const _EmptyState(
                        icon: Icons.medication_outlined,
                        message: 'لا توجد أدوية في الوصفة',
                      )
                    else
                      ..._items.asMap().entries.map(
                        (entry) => Card(
                          elevation: 0,
                          color: Colors.white,
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: _paleTeal,
                              foregroundColor: _teal,
                              child: Icon(Icons.medication_outlined),
                            ),
                            title: Text(
                              entry.value.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              [
                                entry.value.dosage,
                                entry.value.frequency,
                                entry.value.duration,
                                entry.value.notes,
                              ].where((text) => text.isNotEmpty).join(' • '),
                            ),
                            trailing: _editing
                                ? IconButton(
                                    onPressed: () => setState(
                                      () => _items.removeAt(entry.key),
                                    ),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: _danger,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    if (_editing) ...[
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: state.actionLoading ? null : _save,
                        icon: state.actionLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('حفظ التعديلات'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _teal,
                          minimumSize: const Size.fromHeight(52),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _prescriptionField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        readOnly: !_editing,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: _editing ? Colors.white : const Color(0xFFF4F8F8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  Future<void> _addMedicine() async {
    final medicine = await showModalBottomSheet<VisitMedicineInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMedicineSheet(
        knownMedicines: context.read<DoctorDashboardCubit>().state.medicines,
      ),
    );
    if (medicine != null && mounted) {
      setState(() => _items.add(medicine));
    }
  }

  Future<void> _save() async {
    final prescription = _prescription;
    if (prescription == null || _items.isEmpty) {
      _message('يجب أن تحتوي الوصفة على دواء واحد على الأقل.');
      return;
    }
    final success = await context
        .read<DoctorDashboardCubit>()
        .updatePrescription(
          prescriptionId: prescription.id,
          medicalRecordId: prescription.medicalRecordId,
          instructions: _instructions.text,
          notes: _notes.text,
          items: _items,
        );
    if (!mounted) return;
    if (success) {
      setState(() => _editing = false);
      await _load();
      if (mounted) _message('تم تعديل الوصفة بنجاح.');
    } else {
      _message(
        context.read<DoctorDashboardCubit>().state.errorMessage ??
            'تعذر تعديل الوصفة.',
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الوصفة؟'),
        content: const Text('سيتم حذف الوصفة وأدويتها نهائياً.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final success = await context
        .read<DoctorDashboardCubit>()
        .deletePrescription(widget.summary.id);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      _message(
        context.read<DoctorDashboardCubit>().state.errorMessage ??
            'تعذر حذف الوصفة.',
      );
    }
  }

  String _prescriptionStatus(String status) {
    switch (status) {
      case 'pending':
        return 'بانتظار الصرف';
      case 'priced':
        return 'تم التسعير';
      case 'paid':
        return 'مدفوعة';
      case 'dispensed':
        return 'تم الصرف';
      default:
        return status;
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LaboratoryPage extends StatelessWidget {
  final List<DoctorMedicalRecord> records;

  const _LaboratoryPage({required this.records});

  @override
  Widget build(BuildContext context) {
    return _ListScaffold(
      title: 'إحالات التحاليل',
      isEmpty: records.isEmpty,
      emptyIcon: Icons.science_outlined,
      emptyMessage: 'لا توجد إحالات مخبرية حالياً',
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return _SimpleDataCard(
          icon: Icons.science_outlined,
          title: record.patientName,
          subtitle: record.laboratoryNotes.isEmpty
              ? record.diagnosis
              : record.laboratoryNotes,
          trailing: _formatDate(record.date),
        );
      },
    );
  }
}

class _ListScaffold extends StatelessWidget {
  final String title;
  final bool isEmpty;
  final IconData emptyIcon;
  final String emptyMessage;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  const _ListScaffold({
    required this.title,
    required this.isEmpty,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          title: Text(title),
          backgroundColor: _background,
          surfaceTintColor: Colors.transparent,
        ),
        body: isEmpty
            ? _LargeEmptyState(icon: emptyIcon, message: emptyMessage)
            : ListView.builder(
                padding: const EdgeInsets.all(18),
                itemCount: itemCount,
                itemBuilder: itemBuilder,
              ),
      ),
    );
  }
}

class _SimpleDataCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback? onTap;

  const _SimpleDataCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: _whiteCardDecoration(21),
        child: Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: _paleTeal,
              foregroundColor: _teal,
              child: Icon(icon),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            Text(trailing, style: const TextStyle(color: _muted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _PatientDetailsSheet extends StatelessWidget {
  final DoctorAppointment appointment;
  final VoidCallback onStart;

  const _PatientDetailsSheet({
    required this.appointment,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          22,
          12,
          22,
          MediaQuery.paddingOf(context).bottom + 22,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 20),
            _Avatar(
              imageUrl: appointment.patientImage,
              name: appointment.patientName,
              size: 82,
              borderWidth: 3,
            ),
            const SizedBox(height: 11),
            Text(
              appointment.patientName,
              style: const TextStyle(
                color: _ink,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            _DetailsRow(
              icon: Icons.calendar_today_outlined,
              label: 'الموعد',
              value:
                  '${_formatDate(appointment.date)} - ${_displayTime(appointment.time)}',
            ),
            _DetailsRow(
              icon: Icons.medical_services_outlined,
              label: 'نوع الزيارة',
              value: appointment.visitType,
            ),
            if (appointment.phone.isNotEmpty)
              _DetailsRow(
                icon: Icons.phone_outlined,
                label: 'الهاتف',
                value: appointment.phone,
              ),
            if (appointment.email.isNotEmpty)
              _DetailsRow(
                icon: Icons.email_outlined,
                label: 'البريد',
                value: appointment.email,
              ),
            if (appointment.notes.isNotEmpty)
              _DetailsRow(
                icon: Icons.notes_rounded,
                label: 'ملاحظات',
                value: appointment.notes,
              ),
            if (!appointment.isFinished) ...[
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.medical_services_outlined),
                  label: const Text('بدء المعاينة'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _teal,
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailsRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: _paleTeal,
            foregroundColor: _teal,
            child: Icon(icon, size: 21),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 77,
            child: Text(
              label,
              style: const TextStyle(color: _muted, fontSize: 12.5),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitCompletionPage extends StatefulWidget {
  final DoctorAppointment appointment;

  const _VisitCompletionPage({required this.appointment});

  @override
  State<_VisitCompletionPage> createState() => _VisitCompletionPageState();
}

class _VisitCompletionPageState extends State<_VisitCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosis = TextEditingController();
  final _bloodType = TextEditingController();
  final _allergies = TextEditingController();
  final _heartRate = TextEditingController();
  final _diseases = TextEditingController();
  final _notes = TextEditingController();
  final _labNotes = TextEditingController();
  final _prescriptionInstructions = TextEditingController();
  final _prescriptionNotes = TextEditingController();
  final List<VisitMedicineInput> _medicines = [];
  bool _toPharmacy = false;
  bool _toLaboratory = false;
  int _section = 0;

  @override
  void initState() {
    super.initState();
    _bloodType.text = widget.appointment.bloodType;
    _allergies.text = widget.appointment.allergies;
    _diseases.text = widget.appointment.chronicDiseases;
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraft());
  }

  @override
  void dispose() {
    _diagnosis.dispose();
    _bloodType.dispose();
    _allergies.dispose();
    _heartRate.dispose();
    _diseases.dispose();
    _notes.dispose();
    _labNotes.dispose();
    _prescriptionInstructions.dispose();
    _prescriptionNotes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DoctorDashboardCubit>().state;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Column(
            children: [
              _VisitHeader(
                onBack: () => Navigator.pop(context),
                unreadCount: dashboard.unreadCount,
                onNotifications: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BlocProvider.value(
                      value: context.read<DoctorDashboardCubit>(),
                      child: const _NotificationsPage(),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
                    children: [
                      _VisitPatientCard(
                        appointment: widget.appointment,
                        onMedicalFile: () => _showMedicalFile(dashboard),
                      ),
                      const SizedBox(height: 17),
                      _VisitSectionSwitch(
                        selected: _section,
                        onSelected: (value) => setState(() => _section = value),
                      ),
                      const SizedBox(height: 20),
                      const _VisitSectionTitle('التشخيص'),
                      const SizedBox(height: 8),
                      _Input(
                        controller: _diagnosis,
                        label: 'أدخل التشخيص الرئيسي للحالة... *',
                        icon: Icons.medical_services_outlined,
                        required: true,
                      ),
                      const SizedBox(height: 5),
                      const _VisitSectionTitle('الملاحظات'),
                      const SizedBox(height: 8),
                      _Input(
                        controller: _notes,
                        label: 'اكتب ملاحظاتك السريرية هنا...',
                        icon: Icons.assignment_outlined,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 5),
                      const _VisitSectionTitle('البيانات الحيوية'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _Input(
                              controller: _bloodType,
                              label: 'زمرة الدم',
                              icon: Icons.bloodtype_outlined,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: _Input(
                              controller: _heartRate,
                              label: 'نبض القلب',
                              icon: Icons.monitor_heart_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const _VisitSectionTitle('الحساسية / الأمراض المزمنة'),
                      const SizedBox(height: 8),
                      _Input(
                        controller: _allergies,
                        label: 'الحساسيات المسجلة',
                        icon: Icons.shield_outlined,
                      ),
                      _Input(
                        controller: _diseases,
                        label: 'الأمراض المزمنة',
                        icon: Icons.healing_outlined,
                      ),
                      const SizedBox(height: 5),
                      const _VisitSectionTitle('الأدوية الموصوفة'),
                      const SizedBox(height: 8),
                      if (_medicines.isNotEmpty)
                        Container(
                          decoration: _whiteCardDecoration(20),
                          child: Column(
                            children: List.generate(_medicines.length, (index) {
                              final medicine = _medicines[index];
                              return Column(
                                children: [
                                  _MedicineTile(
                                    medicine: medicine,
                                    onDelete: () => setState(
                                      () => _medicines.removeAt(index),
                                    ),
                                  ),
                                  if (index < _medicines.length - 1)
                                    const Divider(height: 1),
                                ],
                              );
                            }),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: _whiteCardDecoration(20),
                          child: const Text(
                            'لم تتم إضافة أدوية إلى الوصفة.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _muted),
                          ),
                        ),
                      const SizedBox(height: 9),
                      OutlinedButton.icon(
                        onPressed: () => _showAddMedicine(dashboard.medicines),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label: const Text('إضافة دواء'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _teal,
                          side: const BorderSide(color: Color(0x77047C87)),
                          minimumSize: const Size.fromHeight(49),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _Input(
                        controller: _prescriptionInstructions,
                        label: 'تعليمات الوصفة العامة',
                        icon: Icons.info_outline_rounded,
                      ),
                      _Input(
                        controller: _prescriptionNotes,
                        label: 'ملاحظات الوصفة',
                        icon: Icons.edit_note_rounded,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      const _VisitSectionTitle('التحويلات'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _ReferralCard(
                              icon: Icons.local_pharmacy_outlined,
                              label: 'تحويل إلى الصيدلية',
                              value: _toPharmacy,
                              onChanged: (value) =>
                                  setState(() => _toPharmacy = value),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: _ReferralCard(
                              icon: Icons.science_outlined,
                              label: 'تحويل إلى المختبر',
                              value: _toLaboratory,
                              onChanged: (value) =>
                                  setState(() => _toLaboratory = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const _VisitSectionTitle('ملاحظات التحويل / المخبر'),
                      const SizedBox(height: 8),
                      _Input(
                        controller: _labNotes,
                        label: 'اكتب ملاحظات التحويل أو تعليمات المخبر...',
                        icon: Icons.description_outlined,
                        maxLines: 3,
                        required: _toLaboratory,
                      ),
                    ],
                  ),
                ),
              ),
              _VisitActions(
                loading: dashboard.actionLoading,
                onSaveDraft: _saveDraft,
                onComplete: _completeVisit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeVisit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await context.read<DoctorDashboardCubit>().completeVisit(
      appointmentId: widget.appointment.id,
      diagnosis: _diagnosis.text,
      bloodType: _bloodType.text,
      allergies: _allergies.text,
      heartRate: _heartRate.text,
      diseases: _diseases.text,
      notes: _notes.text,
      referToPharmacist: _toPharmacy,
      referToLaboratory: _toLaboratory,
      laboratoryNotes: _labNotes.text,
      prescriptionInstructions: _prescriptionInstructions.text,
      prescriptionNotes: _prescriptionNotes.text,
      medicines: List.unmodifiable(_medicines),
    );
    if (success && mounted) Navigator.pop(context);
  }

  Future<void> _saveDraft() async {
    await context.read<DoctorDashboardCubit>().saveVisitDraft(
      appointmentId: widget.appointment.id,
      data: {
        'diagnosis': _diagnosis.text,
        'blood_type': _bloodType.text,
        'allergies': _allergies.text,
        'heart_rate': _heartRate.text,
        'diseases': _diseases.text,
        'notes': _notes.text,
        'laboratory_notes': _labNotes.text,
        'prescription_instructions': _prescriptionInstructions.text,
        'prescription_notes': _prescriptionNotes.text,
        'refer_to_pharmacist': _toPharmacy,
        'refer_to_laboratory': _toLaboratory,
        'medicines': _medicines.map((item) => item.toDraftJson()).toList(),
      },
    );
  }

  void _restoreDraft() {
    if (!mounted) return;
    final draft = context.read<DoctorDashboardCubit>().readVisitDraft(
      widget.appointment.id,
    );
    if (draft == null) return;
    _diagnosis.text = (draft['diagnosis'] ?? '').toString();
    _bloodType.text = (draft['blood_type'] ?? _bloodType.text).toString();
    _allergies.text = (draft['allergies'] ?? _allergies.text).toString();
    _heartRate.text = (draft['heart_rate'] ?? '').toString();
    _diseases.text = (draft['diseases'] ?? _diseases.text).toString();
    _notes.text = (draft['notes'] ?? '').toString();
    _labNotes.text = (draft['laboratory_notes'] ?? '').toString();
    _prescriptionInstructions.text = (draft['prescription_instructions'] ?? '')
        .toString();
    _prescriptionNotes.text = (draft['prescription_notes'] ?? '').toString();
    _toPharmacy = draft['refer_to_pharmacist'] == true;
    _toLaboratory = draft['refer_to_laboratory'] == true;
    final medicines = draft['medicines'];
    if (medicines is List) {
      _medicines
        ..clear()
        ..addAll(
          medicines
              .map(asStringMap)
              .whereType<Map<String, dynamic>>()
              .map(
                (item) => VisitMedicineInput(
                  medicineId: int.tryParse('${item['medicine_id']}') ?? 0,
                  name: (item['name'] ?? 'دواء').toString(),
                  dosage: (item['dosage'] ?? '').toString(),
                  frequency: (item['frequency'] ?? '').toString(),
                  duration: (item['duration'] ?? '').toString(),
                  notes: (item['notes'] ?? '').toString(),
                ),
              ),
        );
    }
    setState(() {});
  }

  Future<void> _showAddMedicine(List<DoctorMedicine> knownMedicines) async {
    final result = await showModalBottomSheet<VisitMedicineInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMedicineSheet(knownMedicines: knownMedicines),
    );
    if (result != null && mounted) setState(() => _medicines.add(result));
  }

  void _showMedicalFile(DoctorDashboardState state) {
    final records = state.medicalRecords.where((record) {
      return (widget.appointment.patientId != 0 &&
              record.patientId == widget.appointment.patientId) ||
          record.patientName == widget.appointment.patientName;
    }).toList();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _background,
      showDragHandle: true,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: records.isEmpty
              ? const _LargeEmptyState(
                  icon: Icons.folder_open_outlined,
                  message: 'لا توجد سجلات سابقة لهذا المريض',
                )
              : ListView(
                  children: records
                      .map((record) => _RecordCard(record: record))
                      .toList(),
                ),
        ),
      ),
    );
  }
}

class _VisitHeader extends StatelessWidget {
  final VoidCallback onBack;
  final int unreadCount;
  final VoidCallback onNotifications;

  const _VisitHeader({
    required this.onBack,
    required this.unreadCount,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onNotifications,
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              backgroundColor: _teal,
              child: const Icon(Icons.notifications_none_rounded, size: 29),
            ),
          ),
          const Expanded(
            child: Text(
              'إتمام الزيارة',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _teal,
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: _teal,
              size: 29,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitPatientCard extends StatelessWidget {
  final DoctorAppointment appointment;
  final VoidCallback onMedicalFile;

  const _VisitPatientCard({
    required this.appointment,
    required this.onMedicalFile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _whiteCardDecoration(23),
      child: Row(
        children: [
          _Avatar(
            imageUrl: appointment.patientImage,
            name: appointment.patientName,
            size: 72,
            borderWidth: 2,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.patientName,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_formatDate(appointment.date)} • ${_displayTime(appointment.time)} • ${appointment.durationMinutes} دقيقة',
                  style: const TextStyle(color: _muted, fontSize: 12.5),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.visitType,
                  style: const TextStyle(color: _muted, fontSize: 12.5),
                ),
                TextButton.icon(
                  onPressed: onMedicalFile,
                  icon: const Icon(Icons.chevron_left_rounded, size: 18),
                  label: const Text('عرض الملف الطبي'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: _teal,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          _StatusChip(status: appointment.status),
        ],
      ),
    );
  }
}

class _VisitSectionSwitch extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _VisitSectionSwitch({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const labels = ['التشخيص', 'الوصفة'];
    return Container(
      height: 51,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(27),
        boxShadow: const [BoxShadow(color: Color(0x0E0C6570), blurRadius: 14)],
      ),
      child: Row(
        children: List.generate(2, (index) {
          final active = selected == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? _teal : Colors.transparent,
                  borderRadius: BorderRadius.circular(27),
                ),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: active ? Colors.white : _muted,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _VisitSectionTitle extends StatelessWidget {
  final String title;

  const _VisitSectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _deepTeal,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _AddMedicineSheet extends StatefulWidget {
  final List<DoctorMedicine> knownMedicines;

  const _AddMedicineSheet({required this.knownMedicines});

  @override
  State<_AddMedicineSheet> createState() => _AddMedicineSheetState();
}

class _AddMedicineSheetState extends State<_AddMedicineSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _dosage = TextEditingController();
  final _frequency = TextEditingController();
  final _duration = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    _frequency.dispose();
    _duration.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          decoration: const BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SheetHandle(),
                  const SizedBox(height: 17),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'إضافة دواء إلى الوصفة',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Input(
                    controller: _name,
                    label: 'اسم الدواء *',
                    icon: Icons.medication_outlined,
                    required: true,
                  ),
                  _Input(
                    controller: _dosage,
                    label: 'الجرعة *',
                    icon: Icons.medication_liquid_outlined,
                    required: true,
                  ),
                  _Input(
                    controller: _frequency,
                    label: 'التكرار (مثال: كل 12 ساعة) *',
                    icon: Icons.schedule_outlined,
                    required: true,
                  ),
                  _Input(
                    controller: _duration,
                    label: 'المدة (مثال: 7 أيام) *',
                    icon: Icons.date_range_outlined,
                    required: true,
                  ),
                  _Input(
                    controller: _notes,
                    label: 'ملاحظات الدواء',
                    icon: Icons.notes_outlined,
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('إضافة الدواء'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _teal,
                        minimumSize: const Size.fromHeight(52),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final enteredName = _name.text.trim();
    final normalizedName = enteredName.toLowerCase();
    DoctorMedicine? knownMedicine;
    for (final medicine in widget.knownMedicines) {
      if (medicine.name.trim().toLowerCase() == normalizedName) {
        knownMedicine = medicine;
        break;
      }
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(
      VisitMedicineInput(
        medicineId: knownMedicine?.id ?? 0,
        name: enteredName,
        dosage: _dosage.text.trim(),
        frequency: _frequency.text.trim(),
        duration: _duration.text.trim(),
        notes: _notes.text.trim(),
      ),
    );
  }
}

class _MedicineTile extends StatelessWidget {
  final VisitMedicineInput medicine;
  final VoidCallback onDelete;

  const _MedicineTile({required this.medicine, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: _paleTeal,
            foregroundColor: _teal,
            child: Icon(Icons.medication_outlined),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${medicine.name} ${medicine.dosage}',
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${medicine.frequency} • ${medicine.duration}',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            color: _danger,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _ReferralCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ReferralCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: _whiteCardDecoration(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: _paleTeal,
                foregroundColor: _teal,
                child: Icon(icon, size: 20),
              ),
              const Spacer(),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeTrackColor: _teal,
              ),
            ],
          ),
          Text(
            label,
            maxLines: 1,
            style: const TextStyle(color: _ink, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _VisitActions extends StatelessWidget {
  final bool loading;
  final VoidCallback onSaveDraft;
  final VoidCallback onComplete;

  const _VisitActions({
    required this.loading,
    required this.onSaveDraft,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Color(0x180B5962),
            blurRadius: 22,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: loading ? null : onComplete,
              icon: loading
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.assignment_turned_in_outlined),
              label: Text(loading ? 'جارٍ الحفظ...' : 'حفظ وإنهاء الزيارة'),
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: loading ? null : onSaveDraft,
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ كمسودة'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _teal,
                side: const BorderSide(color: _teal),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExaminationSheet extends StatefulWidget {
  final DoctorAppointment appointment;

  const _ExaminationSheet({required this.appointment});

  @override
  State<_ExaminationSheet> createState() => _ExaminationSheetState();
}

class _ExaminationSheetState extends State<_ExaminationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosis = TextEditingController();
  final _bloodType = TextEditingController();
  final _allergies = TextEditingController();
  final _heartRate = TextEditingController();
  final _diseases = TextEditingController();
  final _notes = TextEditingController();
  final _labNotes = TextEditingController();
  bool _toPharmacy = false;
  bool _toLaboratory = false;

  @override
  void dispose() {
    _diagnosis.dispose();
    _bloodType.dispose();
    _allergies.dispose();
    _heartRate.dispose();
    _diseases.dispose();
    _notes.dispose();
    _labNotes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .92,
        ),
        decoration: const BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 22,
              ),
              children: [
                const Center(child: _SheetHandle()),
                const SizedBox(height: 18),
                Text(
                  'معاينة ${widget.appointment.patientName}',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'أدخل بيانات السجل الطبي بدقة',
                  style: TextStyle(color: _muted, fontSize: 13.5),
                ),
                const SizedBox(height: 19),
                _Input(
                  controller: _diagnosis,
                  label: 'التشخيص *',
                  icon: Icons.medical_information_outlined,
                  required: true,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _Input(
                        controller: _bloodType,
                        label: 'زمرة الدم',
                        icon: Icons.bloodtype_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Input(
                        controller: _heartRate,
                        label: 'نبض القلب',
                        icon: Icons.monitor_heart_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                _Input(
                  controller: _allergies,
                  label: 'الحساسيات',
                  icon: Icons.warning_amber_rounded,
                ),
                _Input(
                  controller: _diseases,
                  label: 'الأمراض المزمنة',
                  icon: Icons.healing_outlined,
                ),
                _Input(
                  controller: _notes,
                  label: 'ملاحظات المعاينة',
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                ),
                SwitchListTile.adaptive(
                  value: _toPharmacy,
                  onChanged: (value) => setState(() => _toPharmacy = value),
                  activeTrackColor: _teal,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'إحالة إلى الصيدلية',
                    style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
                  ),
                  secondary: const Icon(
                    Icons.medication_outlined,
                    color: _teal,
                  ),
                ),
                SwitchListTile.adaptive(
                  value: _toLaboratory,
                  onChanged: (value) => setState(() => _toLaboratory = value),
                  activeTrackColor: _teal,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'إحالة إلى المختبر',
                    style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
                  ),
                  secondary: const Icon(Icons.science_outlined, color: _teal),
                ),
                if (_toLaboratory)
                  _Input(
                    controller: _labNotes,
                    label: 'الفحوصات المطلوبة *',
                    icon: Icons.biotech_outlined,
                    required: true,
                    maxLines: 2,
                  ),
                const SizedBox(height: 9),
                BlocBuilder<DoctorDashboardCubit, DoctorDashboardState>(
                  builder: (context, state) => FilledButton.icon(
                    onPressed: state.actionLoading ? null : _submit,
                    icon: state.actionLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      state.actionLoading
                          ? 'جارٍ الحفظ...'
                          : 'حفظ وإنهاء المعاينة',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _teal,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await context
        .read<DoctorDashboardCubit>()
        .createMedicalRecord(
          appointmentId: widget.appointment.id,
          diagnosis: _diagnosis.text,
          bloodType: _bloodType.text,
          allergies: _allergies.text,
          heartRate: _heartRate.text,
          diseases: _diseases.text,
          notes: _notes.text,
          referToPharmacist: _toPharmacy,
          referToLaboratory: _toLaboratory,
          laboratoryNotes: _labNotes.text,
        );
    if (success && mounted) Navigator.pop(context);
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool required;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Input({
    required this.controller,
    required this.label,
    required this.icon,
    this.required = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                  ? 'هذا الحقل مطلوب'
                  : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _teal),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(color: Color(0xFFE2ECEE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(color: _teal, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _DoctorBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _DoctorBottomBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, Icons.home_outlined, 'الرئيسية'),
      (Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'مواعيدي'),
      (Icons.groups_rounded, Icons.groups_outlined, 'مرضاي'),
      (Icons.folder_rounded, Icons.folder_outlined, 'السجل'),
      (Icons.person_rounded, Icons.person_outline_rounded, 'حسابي'),
    ];
    return SafeArea(
      top: false,
      child: Container(
        height: 86,
        padding: const EdgeInsets.fromLTRB(9, 7, 9, 6),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Color(0x160B5962),
              blurRadius: 25,
              offset: Offset(0, -7),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = selectedIndex == index;
            return Expanded(
              child: InkWell(
                onTap: () => onSelected(index),
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFE3F2F6)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selected ? item.$1 : item.$2,
                        color: selected ? _teal : const Color(0xFF596A75),
                        size: 24,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        item.$3,
                        style: TextStyle(
                          color: selected ? _teal : const Color(0xFF596A75),
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final double borderWidth;

  const _Avatar({
    required this.imageUrl,
    required this.name,
    required this.size,
    required this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join();
    final fallback = Container(
      color: _paleTeal,
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? 'ط' : initials,
        style: TextStyle(
          color: _deepTeal,
          fontSize: size * .3,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(borderWidth),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x22004750),
            blurRadius: 11,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl == null || imageUrl!.isEmpty
            ? fallback
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 5,
      decoration: BoxDecoration(
        color: const Color(0xFFD8E2E5),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool light;

  const _EmptyState({
    required this.icon,
    required this.message,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : _teal;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 36),
        const SizedBox(height: 9),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: light ? Colors.white : _muted,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LargeEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _LargeEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: _EmptyState(icon: icon, message: message),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(child: CircularProgressIndicator(color: _teal)),
    );
  }
}

class _FailureView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FailureView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, color: _teal, size: 52),
              const SizedBox(height: 15),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 15),
              ),
              const SizedBox(height: 17),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
                style: FilledButton.styleFrom(backgroundColor: _teal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _whiteCardDecoration(double radius) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: const [
      BoxShadow(color: Color(0x100C6570), blurRadius: 20, offset: Offset(0, 8)),
    ],
  );
}

String _displayTime(String value) {
  if (value.isEmpty) return '--:--';
  final parts = value.split(':');
  final hour = int.tryParse(parts.first) ?? 0;
  final minute = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
  final suffix = hour >= 12 ? 'م' : 'ص';
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '$displayHour:$minute $suffix';
}

String _formatDate(String value) {
  if (value.isEmpty) return 'غير محدد';
  final date = DateTime.tryParse(value.replaceAll('/', '-'));
  if (date == null) return value;
  return '${date.day}/${date.month}/${date.year}';
}

String _statusLabel(String value) {
  switch (value) {
    case 'completed':
      return 'مكتمل';
    case 'cancelled':
    case 'canceled':
      return 'ملغي';
    case 'no_show':
      return 'لم يحضر';
    default:
      return value.isEmpty ? 'غير محدد' : value;
  }
}

String _arabicWeekday(int weekday) {
  const names = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];
  return names[(weekday - 1).clamp(0, 6)];
}

String _arabicMonth(int month) {
  const names = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  return names[(month - 1).clamp(0, 11)];
}
