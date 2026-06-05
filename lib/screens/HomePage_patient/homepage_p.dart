import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/clinic_states.dart';
import 'package:nabad/Cubits/department_cubit.dart';
import 'package:nabad/Cubits/doctor_cubit.dart';
import 'package:nabad/Cubits/user_cubit.dart';
import 'package:nabad/Cubits/user_state.dart';
import 'package:nabad/Models/department_model.dart';
import 'package:nabad/Models/doctor_model.dart';
import 'package:nabad/core/router/app_router.dart';
import 'package:nabad/core/theme/nabad_colors.dart';
import 'package:nabad/widgets/soft_ring.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();

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
    context.read<UserCubit>().getPatientProfile();
    context.read<DepartmentCubit>().getDepartments();
    context.read<DoctorCubit>().getAllDoctors();
  }

  @override
  void dispose() {
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

  // لما يضغط على تخصص: يجيب أطباؤه ويسكرول للأسفل
  void _onDeptTap(DepartmentModel dept) {
    context.read<DoctorCubit>().getDoctorsByDepartment(dept.id);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildHome();
      case 1:
        return _buildAllDoctors();
      case 2:
        return _buildAppointments();
      case 3:
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
        const _SearchBox(),
        const SizedBox(height: 20),
        _TipsCarousel(tips: _tips),
        const SizedBox(height: 22),
        const _SectionHeader(title: 'المواعيد القادمة', action: 'الكل'),
        const SizedBox(height: 10),
        const _UpcomingAppointmentCard(),
        const SizedBox(height: 22),
        const _SectionHeader(title: 'التخصصات الطبية'),
        const SizedBox(height: 12),
        BlocBuilder<DepartmentCubit, DepartmentState>(
          builder: (context, state) {
            if (state is DepartmentLoading) {
              return const SizedBox(
                height: 90,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            if (state is DepartmentError) {
              return _ErrorRetry(
                message: state.message,
                onRetry: () => context.read<DepartmentCubit>().getDepartments(),
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
        const SizedBox(height: 22),
        const _SectionHeader(title: 'أطباء مقترحون', action: 'عرض الكل'),
        const SizedBox(height: 10),
        BlocBuilder<DoctorCubit, DoctorState>(
          builder: (context, state) {
            if (state is DoctorInitial) {
              // لو ما اشتغل الـ fetch لسبب ما، نطلقه هون
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<DoctorCubit>().getAllDoctors();
              });
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
              if (state.doctors.isEmpty) {
                return const _EmptyDoctors();
              }
              return Column(
                children: state.doctors
                    .map(
                      (doctor) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _DoctorCard(doctor: doctor),
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

  // تاب الاطباء
  Widget _buildAllDoctors() {
    return BlocBuilder<DoctorCubit, DoctorState>(
      builder: (context, state) {
        if (state is DoctorInitial) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<DoctorCubit>().getAllDoctors();
          });
          return const Center(child: CircularProgressIndicator());
        }
        if (state is DoctorLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is DoctorError) {
          return Center(
            child: _ErrorRetry(
              message: state.message,
              onRetry: () => context.read<DoctorCubit>().getAllDoctors(),
            ),
          );
        }
        if (state is DoctorSuccess) {
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: state.doctors.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _DoctorCard(doctor: state.doctors[i]),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAppointments() {
    return const Center(
      child: Text(
        'مواعيدي\nقريباً',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: NabadColors.mutedText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildProfile() {
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        // منع الرجوع للـ welcome — الضغط على باك بيطلع من التطبيق
        if (!didPop) {
          // لا نفعل شيء، أو يمكن إظهار dialog "هل تريد الخروج؟"
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: NabadColors.background,
          body: SafeArea(
            child: Stack(
              children: [
                const Positioned(top: 96, right: -78, child: SoftRing(size: 230)),
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
              if (index == 3) {
                Navigator.pushNamed(context, AppRoutes.patientProfile);
              } else {
                setState(() => _selectedIndex = index);
                if (index == 0) {
                  context.read<DoctorCubit>().getAllDoctors();
                }
                if (index == 1) {
                  context.read<DoctorCubit>().getAllDoctors();
                }
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
            ? 'أهلاً، ${state.patient.user.firstName} نتمنى لك يوماً صحياً 🤗'
            : ' نتمنى لك يوماً صحياً ';

        return Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: NabadColors.primary.withAlpha(28)),
                image: const DecorationImage(
                  image: AssetImage('assets/images/Female.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const Spacer(),
            Text(
              greeting,
              style: const TextStyle(
                color: NabadColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            IconButton.filled(
              onPressed: () {},
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
          ],
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
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                    color: const Color(0xFFC9F3F8),
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
                    dept.department_name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: NabadColors.deepTeal,
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

class _DoctorCard extends StatelessWidget {
  final DoctorModel doctor;

  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(238),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: NabadColors.primary.withAlpha(14)),
        boxShadow: [
          BoxShadow(
            color: NabadColors.primary.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // صورة الطبيب
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: doctor.profileImage != null
                ? Image.network(
                    doctor.profileImage!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _AvatarFallback(initials: _initials(doctor.fullName)),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: 72,
                        height: 72,
                        color: const Color(0xFFC9F3F8),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  )
                : _AvatarFallback(initials: _initials(doctor.fullName)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. ${doctor.fullName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: NabadColors.darkText,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  doctor.specialization ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: NabadColors.mutedText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (doctor.yearsOfExperience != null) ...[
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFFE2A228),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${doctor.yearsOfExperience} سنوات خبرة',
                        style: const TextStyle(
                          color: Color(0xFFE2A228),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            onPressed: () {},
            style: IconButton.styleFrom(
              foregroundColor: NabadColors.primary,
              side: BorderSide(color: NabadColors.primary.withAlpha(35)),
              fixedSize: const Size(42, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    return parts.take(2).map((w) => w.isNotEmpty ? w[0] : '').join();
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initials;
  const _AvatarFallback({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      color: const Color(0xFFC9F3F8),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: NabadColors.primary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _EmptyDoctors extends StatelessWidget {
  const _EmptyDoctors();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'لا يوجد أطباء في هذا التخصص حالياً',
          style: TextStyle(
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
            message,
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
            label: const Text('إعادة المحاولة'),
            style: TextButton.styleFrom(foregroundColor: NabadColors.primary),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(238),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: NabadColors.primary.withAlpha(14)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: NabadColors.mutedText),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              decoration: const InputDecoration(
                hintText: 'ابحث عن طبيب أو تخصص...',
                hintStyle: TextStyle(
                  color: NabadColors.mutedText,
                  fontWeight: FontWeight.w700,
                ),
                border: InputBorder.none,
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
        separatorBuilder: (_, __) => const SizedBox(width: 14),
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
                  tip.title,
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
                  tip.subtitle,
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
  final String? action;
  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: NabadColors.darkText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: NabadColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
            child: Text(action!),
          ),
      ],
    );
  }
}

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
    const items = [
      _BottomItem(icon: Icons.home_rounded, label: 'الرئيسية'),
      _BottomItem(icon: Icons.groups_rounded, label: 'الأطباء'),
      _BottomItem(icon: Icons.calendar_month_rounded, label: 'مواعيدي'),
      _BottomItem(icon: Icons.person_rounded, label: 'حسابي'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
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