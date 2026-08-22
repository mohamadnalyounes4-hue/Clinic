import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/states/clinic_states.dart';
import 'package:nabad/Cubits/cubits/department_cubit.dart';
import 'package:nabad/Cubits/cubits/doctor_cubit.dart';
import 'package:nabad/Cubits/cubits/points_cubit.dart';
import 'package:nabad/Cubits/cubits/patient_notification_cubit.dart';
import 'package:nabad/Cubits/states/points_state.dart';
import 'package:nabad/Cubits/states/patient_notification_state.dart';
import 'package:nabad/Cubits/cubits/user_cubit.dart';
import 'package:nabad/Cubits/states/user_state.dart';
import 'package:nabad/Models/department_model.dart';
import 'package:nabad/Models/doctor_model.dart';
import 'package:nabad/core/router/app_router.dart';
import 'package:nabad/core/localization/app_localizations.dart';
import 'package:nabad/core/theme/nabad_colors.dart';
import 'package:nabad/core/notifications/push_notification_service.dart';
import 'package:nabad/screens/HomePage_patient/patient_profile_screen.dart';
import 'package:nabad/screens/HomePage_patient/doctor/department_doctors_screen.dart';
import 'package:nabad/screens/HomePage_patient/doctor/doctor_profile_booking_screen.dart';
import 'package:nabad/screens/HomePage_patient/appointments_screen.dart';
import 'package:nabad/widgets/soft_ring.dart';
import 'package:nabad/widgets/doctors/patient_doctor_card.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _doctorSearchController = TextEditingController();
  late final int _doctorShuffleSeed;
  String _doctorSearchQuery = '';
  Timer? _pointsRefreshTimer;

  final List<_HealthTip> _tips = const [
    _HealthTip(
      title: 'أهمية الترطيب اليومي',
      subtitle: 'اشرب 8 أكواب يومياً لتحافظ على نشاطك.',
      image: 'assets/images/ddd.jpg',
    ),
    _HealthTip(
      title: 'فحص العين الدوري',
      subtitle: 'زيارة قصيرة قد تكشف مشاكل مبكرة.',
      image: 'assets/images/11.jpg',
    ),
    _HealthTip(
      title: 'العناية بصحة القلب',
      subtitle: 'نمط حياة هادئ ومشي يومي يصنع فرقاً.',
      image: 'assets/images/10.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _doctorShuffleSeed = DateTime.now().microsecondsSinceEpoch;
    WidgetsBinding.instance.addObserver(this);
    context.read<UserCubit>().getPatientProfile();
    context.read<DepartmentCubit>().getDepartments();
    context.read<DoctorCubit>().getAllDoctors();
    context.read<PointsCubit>().getPointsSummary();
    context.read<PatientNotificationCubit>().loadUnreadCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.instance.processPendingNavigation();
    });
    _pointsRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted && _selectedIndex == 0) {
        context.read<PointsCubit>().getPointsSummary();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _selectedIndex == 0) {
      context.read<PointsCubit>().getPointsSummary();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pointsRefreshTimer?.cancel();
    _doctorSearchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // أيقونة لكل تخصص حسب اسمه
  IconData _iconForDept(String name) {
    final n = name.toLowerCase();
    if (n.contains('قلب') || n.contains('cardio')) {
      return Icons.favorite_border_rounded;
    }
    if (n.contains('أسنان') || n.contains('سنان') || n.contains('dent')) {
      return Icons.health_and_safety_rounded;
    }
    if (n.contains('عيون') ||
        n.contains('عين') ||
        n.contains('eye') ||
        n.contains('ophthal')) {
      return Icons.remove_red_eye_outlined;
    }
    if (n.contains('جلد') || n.contains('derm')) {
      return Icons.spa_outlined;
    }
    if (n.contains('عظام') || n.contains('ortho')) {
      return Icons.accessibility_new_rounded;
    }
    if (n.contains('أطفال') || n.contains('طفل') || n.contains('pedia')) {
      return Icons.child_care_rounded;
    }
    if (n.contains('نفس') || n.contains('psych')) {
      return Icons.psychology_outlined;
    }
    if (n.contains('باطن') || n.contains('intern')) {
      return Icons.medical_information_outlined;
    }
    return Icons.local_hospital_outlined;
  }

  // كل اختصاص يفتح بصفحة مستقلة وبـ Cubit منفصل حتى تبقى قائمة الرئيسية كما هي.
  void _onDeptTap(DepartmentModel dept) {
    final api = context.read<DoctorCubit>().api;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => DoctorCubit(api: api)..getDoctorsByDepartment(dept.id),
          child: DepartmentDoctorsScreen(department: dept),
        ),
      ),
    );
  }

  List<DoctorModel> _homeDoctors(List<DoctorModel> doctors) {
    final query = _doctorSearchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      return doctors
          .where((doctor) => doctor.fullName.toLowerCase().contains(query))
          .toList();
    }

    final shuffled = List<DoctorModel>.of(doctors)
      ..shuffle(Random(_doctorShuffleSeed));
    return shuffled.take(4).toList();
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildHome();
      case 1:
        return _buildAppointments();
      case 2:
        return _buildProfile();
      default:
        return _buildHome();
    }
  }

  Widget _buildHome() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _PatientHeader(),
        const SizedBox(height: 18),
        _SearchBox(
          controller: _doctorSearchController,
          query: _doctorSearchQuery,
          onChanged: (value) => setState(() => _doctorSearchQuery = value),
          onClear: () {
            _doctorSearchController.clear();
            setState(() => _doctorSearchQuery = '');
          },
        ),
        if (_doctorSearchQuery.trim().isEmpty) ...[
          const SizedBox(height: 16),
          const _PointsBalanceCard(),
          const SizedBox(height: 20),
          _TipsCarousel(tips: _tips),
          const SizedBox(height: 22),
          _SectionHeader(title: context.tr('التخصصات الطبية')),
          const SizedBox(height: 12),
          BlocBuilder<DepartmentCubit, DepartmentState>(
            builder: (context, state) {
              if (state is DepartmentLoading) {
                return const SizedBox(
                  height: 90,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              if (state is DepartmentError) {
                return _ErrorRetry(
                  message: state.message,
                  onRetry: () =>
                      context.read<DepartmentCubit>().getDepartments(),
                );
              }
              if (state is DepartmentSuccess) {
                return _DepartmentGrid(
                  departments: state.departments,
                  iconForDept: _iconForDept,
                  onTap: _onDeptTap,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        const SizedBox(height: 22),
        _SectionHeader(
          title: context.tr(
            _doctorSearchQuery.trim().isEmpty ? 'أطباء مقترحون' : 'نتائج البحث',
          ),
        ),
        const SizedBox(height: 10),
        BlocBuilder<DoctorCubit, DoctorState>(
          builder: (context, state) {
            if (state is DoctorInitial) {
              // لو ما اشتغل الـ fetch لسبب ما، نطلقه هون
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            if (state is DoctorLoading) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            if (state is DoctorError) {
              return _ErrorRetry(
                message: state.message,
                onRetry: () => context.read<DoctorCubit>().getAllDoctors(),
              );
            }
            if (state is DoctorSuccess) {
              final doctors = _homeDoctors(state.doctors);
              if (doctors.isEmpty) {
                return _EmptyDoctors(hasSearch: _doctorSearchQuery.isNotEmpty);
              }
              return Column(
                children: doctors
                    .map(
                      (doctor) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PatientDoctorCard(
                          doctor: doctor,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DoctorProfileBookingScreen(doctor: doctor),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildAppointments() {
    return const AppointmentsScreen();
  }

  Widget _buildProfile() {
    return const PatientProfileScreen();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // منع الرجوع للـ welcome — الضغط على باك بيطلع من التطبيق
        if (!didPop) {
          SystemNavigator.pop();
          // لا نفعل شيء، أو يمكن إظهار dialog "هل تريد الخروج؟"
        }
      },
      child: Directionality(
        textDirection: context.l10n.isArabic
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Stack(
              children: [
                const Positioned(
                  top: 96,
                  right: -78,
                  child: SoftRing(size: 230),
                ),
                Positioned(
                  left: -48,
                  bottom: 118,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.045,
                      child: Image.asset(
                        'assets/images/logoIcon.png',
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                _buildCurrentPage(),
              ],
            ),
          ),
          bottomNavigationBar: _PatientBottomBar(
            selectedIndex: _selectedIndex,
            onChanged: (index) {
              setState(() => _selectedIndex = index);
              if (index == 0) {
                context.read<DoctorCubit>().getAllDoctors();
                context.read<PointsCubit>().getPointsSummary();
              }
              if (index == 2) {
                context.read<UserCubit>().getPatientProfile();
              }
            },
          ),
        ),
      ),
    );
  }
}

class _PatientHeader extends StatelessWidget {
  const _PatientHeader();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        final String greeting = state is PatientProfileSuccess
            ? context.tr('أهلاً، {name}', {
                'name': state.patient.user.firstName,
              })
            : context.tr('نتمنى لك يوماً صحياً 🤗');

        return Column(
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: NabadColors.primary.withAlpha(28),
                    ),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/Female.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 98,
                      height: 48,
                      fit: BoxFit.contain,
                      semanticLabel: 'Nabd',
                    ),
                  ),
                ),
                BlocBuilder<PatientNotificationCubit, PatientNotificationState>(
                  buildWhen: (previous, current) =>
                      previous.unreadCount != current.unreadCount,
                  builder: (context, notificationState) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton.filled(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.patientNotifications,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: NabadColors.primary,
                            fixedSize: const Size(46, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(17),
                            ),
                          ),
                          icon: const Icon(Icons.notifications_none_rounded),
                        ),
                        if (notificationState.unreadCount > 0)
                          Positioned(
                            top: -4,
                            left: -4,
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth: 19,
                                minHeight: 19,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE45B5B),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                notificationState.unreadCount > 99
                                    ? '99+'
                                    : '${notificationState.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                greeting,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: NabadColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PointsBalanceCard extends StatelessWidget {
  const _PointsBalanceCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PointsCubit, PointsState>(
      builder: (context, state) {
        // نظام النقاط مش نشط أو لسه بيحمّل أو حصل خطأ → منخفيش الهوم بسببه
        if (state is! PointsSuccess || !state.summary.loyaltyActive) {
          return const SizedBox.shrink();
        }

        final summary = state.summary;
        final unit = summary.pointsPerUnit;
        final remainder = unit > 0 ? summary.pointsBalance % unit : 0;
        final progress = unit > 0 ? remainder / unit : 0.0;
        final pointsLeft = unit > 0 ? unit - remainder : 0;
        final hasReadyDiscount =
            unit > 0 && summary.pointsBalance >= summary.pointsPerUnit;
        return InkWell(
          onTap: () async {
            await Navigator.pushNamed(context, AppRoutes.pointsHistory);
            if (context.mounted) {
              context.read<PointsCubit>().getPointsSummary();
            }
          },
          borderRadius: BorderRadius.circular(26),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF35AFC5), NabadColors.primary],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: NabadColors.primary.withAlpha(45),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: -18,
                  top: -30,
                  child: Icon(
                    Icons.stars_rounded,
                    size: 100,
                    color: Colors.white.withAlpha(18),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 13,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(28),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: Colors.white.withAlpha(35),
                              ),
                            ),
                            child: const Icon(
                              Icons.stars_rounded,
                              color: NabadColors.starColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              context.tr('رصيد نقاطك'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(24),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  context.tr('التفاصيل'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 11,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            child: Text(
                              '${summary.pointsBalance}',
                              key: ValueKey(summary.pointsBalance),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 5,
                              bottom: 2,
                            ),
                            child: Text(
                              context.tr('نقطة'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (state.pointsChange != 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: state.pointsChange > 0
                                    ? const Color(0xFFDCFCE7).withAlpha(235)
                                    : const Color(0xFFFFE4E6).withAlpha(235),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${state.pointsChange > 0 ? '+' : ''}${state.pointsChange}',
                                style: TextStyle(
                                  color: state.pointsChange > 0
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFBE123C),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 9),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: hasReadyDiscount ? 1 : progress,
                          minHeight: 5,
                          backgroundColor: Colors.white.withAlpha(28),
                          valueColor: const AlwaysStoppedAnimation(
                            NabadColors.starColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        hasReadyDiscount
                            ? context.tr(
                                'لديك خصم جاهز للاستخدام في حجزك القادم',
                              )
                            : context.tr(
                                'باقي {left} نقطة لتحصل على خصم {discount}%',
                                {
                                  'left': pointsLeft,
                                  'discount': summary.discountPerUnit
                                      .toStringAsFixed(0),
                                },
                              ),
                        style: TextStyle(
                          color: Colors.white.withAlpha(215),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DepartmentGrid extends StatelessWidget {
  final List<DepartmentModel> departments;
  final IconData Function(String) iconForDept;
  final void Function(DepartmentModel) onTap;

  const _DepartmentGrid({
    required this.departments,
    required this.iconForDept,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true,
        itemCount: departments.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final dept = departments[i];
          return InkWell(
            onTap: () => onTap(dept),
            borderRadius: BorderRadius.circular(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.surface
                        : const Color(0xFFC9F3F8),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    iconForDept(dept.department_name),
                    color: NabadColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 66,
                  child: Text(
                    context.tr(dept.department_name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmptyDoctors extends StatelessWidget {
  final bool hasSearch;

  const _EmptyDoctors({this.hasSearch = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          context.tr(
            hasSearch
                ? 'لا يوجد طبيب بهذا الاسم.'
                : 'لا يوجد أطباء متاحون حالياً.',
          ),
          style: const TextStyle(
            color: NabadColors.mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.tr(message),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: NabadColors.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.tr('إعادة المحاولة')),
            style: TextButton.styleFrom(foregroundColor: NabadColors.primary),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBox({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: NabadColors.primary.withAlpha(14)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: NabadColors.mutedText),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              decoration: InputDecoration(
                hintText: context.tr('ابحث عن طبيب بالاسم...'),
                hintStyle: const TextStyle(
                  color: NabadColors.mutedText,
                  fontWeight: FontWeight.w700,
                ),
                border: InputBorder.none,
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: onClear,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: NabadColors.mutedText,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipsCarousel extends StatelessWidget {
  final List<_HealthTip> tips;
  const _TipsCarousel({required this.tips});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true,
        itemCount: tips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, i) => _TipCard(tip: tips[i]),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final _HealthTip tip;
  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: NabadColors.primary,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: NabadColors.primary.withAlpha(28),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(tip.image, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomRight,
                end: Alignment.topLeft,
                colors: [
                  NabadColors.deepTeal.withAlpha(225),
                  NabadColors.primary.withAlpha(115),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Positioned(
            right: 18,
            left: 18,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(tip.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(tip.subtitle),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withAlpha(222),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

// Kept as a standalone design component, but intentionally hidden from home.
// ignore: unused_element
class _UpcomingAppointmentCard extends StatelessWidget {
  const _UpcomingAppointmentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF35AFC5),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF35AFC5).withAlpha(45),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'د. سارة المنصور',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'أخصائية طب العيون',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '10:30 ص',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'غداً، 12 أكتوبر',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(32),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.map_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: NabadColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text(
                      'تأكيد الموعد',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
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
}

class _PatientBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _PatientBottomBar({
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _BottomItem(icon: Icons.home_rounded, label: context.tr('الرئيسية')),
      _BottomItem(
        icon: Icons.calendar_month_rounded,
        label: context.tr('مواعيدي'),
      ),
      _BottomItem(icon: Icons.person_rounded, label: context.tr('حسابي')),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: NabadColors.primary.withAlpha(18),
            blurRadius: 24,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final bool isSelected = selectedIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(index),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? NabadColors.primary.withAlpha(22)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 22,
                      color: isSelected
                          ? NabadColors.primary
                          : NabadColors.mutedText,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? NabadColors.primary
                            : NabadColors.mutedText,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _HealthTip {
  final String title;
  final String subtitle;
  final String image;
  const _HealthTip({
    required this.title,
    required this.subtitle,
    required this.image,
  });
}

class _BottomItem {
  final IconData icon;
  final String label;
  const _BottomItem({required this.icon, required this.label});
}
