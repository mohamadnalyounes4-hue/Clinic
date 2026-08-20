import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/cubits/appointment_cubit.dart';
import 'package:nabad/Cubits/cubits/medicine_reminder_cubit.dart';
import 'package:nabad/Cubits/cubits/patient_medical_record_cubit.dart';
import 'package:nabad/Cubits/cubits/user_cubit.dart';
import 'package:nabad/Cubits/states/appointment_state.dart';
import 'package:nabad/Cubits/states/medicine_reminder_state.dart';
import 'package:nabad/Cubits/states/patient_medical_record_state.dart';
import 'package:nabad/Cubits/states/user_state.dart';
import 'package:nabad/Models/appointment_model.dart';
import 'package:nabad/Models/patient_model.dart';
import 'package:nabad/Models/patient_medical_record_model.dart';
import 'package:nabad/core/router/app_router.dart';
import 'package:nabad/core/theme/nabad_colors.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<UserCubit>().state;
      if (state is! PatientProfileSuccess && state is! PatientProfileLoading) {
        context.read<UserCubit>().getPatientProfile();
      }
      context.read<AppointmentCubit>().getAppointments();
      context.read<PatientMedicalRecordCubit>().loadMedicalFile();
      context.read<MedicineReminderCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocConsumer<UserCubit, UserState>(
        listener: (context, state) {
          if (state is LogoutSuccess) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.welcome,
              (route) => false,
            );
          }
        },
        builder: (context, state) {
          if (state is PatientProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PatientProfileError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 52,
                    color: NabadColors.mutedText,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    style: const TextStyle(color: NabadColors.mutedText),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.read<UserCubit>().getPatientProfile(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة المحاولة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NabadColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          if (state is PatientProfileSuccess) {
            return BlocBuilder<
              PatientMedicalRecordCubit,
              PatientMedicalRecordState
            >(
              builder: (context, medicalState) => _ProfileContent(
                patient: state.patient,
                medicalState: medicalState,
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ProfileContent extends StatelessWidget {
  final PatientModel patient;
  final PatientMedicalRecordState medicalState;

  const _ProfileContent({required this.patient, required this.medicalState});

  String _bloodTypeLabel(String? bt) =>
      (bt == null || bt.isEmpty) ? 'غير محدد' : bt.toUpperCase();

  String _formatDate(String? d) {
    if (d == null || d.isEmpty) return 'غير محدد';
    try {
      final parts = d.split('-');
      if (parts.length != 3) return d;
      const months = [
        '',
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
      final month = int.tryParse(parts[1]) ?? 0;
      return '${parts[2]} ${months[month]} ${parts[0]}';
    } catch (_) {
      return d;
    }
  }

  String _appointmentReminder(AppointmentModel appointment) {
    final doctor = appointment.doctorName.isEmpty
        ? 'الطبيب'
        : 'د. ${appointment.doctorName}';
    final specialty = appointment.specialty.isEmpty
        ? ''
        : '${appointment.specialty}\n';
    return '$doctor\n$specialty${_formatDate(appointment.date)} • ${appointment.time}';
  }

  @override
  Widget build(BuildContext context) {
    final user = patient.user;
    final latestRecord = medicalState.latestRecord;
    final latestBloodType = latestRecord?.bloodType.isNotEmpty == true
        ? latestRecord!.bloodType
        : patient.bloodType;
    final heartRate = latestRecord?.heartRate?.toString() ?? '--';
    final allergies = latestRecord?.allergies.isNotEmpty == true
        ? latestRecord!.allergies
        : 'لا توجد بيانات';
    final diseases = latestRecord?.diseases.isNotEmpty == true
        ? latestRecord!.diseases
        : 'لا توجد بيانات';
    final fullName = '${user.firstName} ${user.lastName}';
    final initials = fullName
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ─── Header ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
            decoration: const BoxDecoration(
              color: NabadColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withAlpha(80),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ملف المريض الطبي', // تم وضع نص بدلاً من النص الفارغ
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Health Overview ──────────────
                const _SectionTitle(title: 'نظرة صحية عامة'),
                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        height: 170,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC9F3F8),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.favorite_border_rounded,
                                  color: NabadColors.primary,
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                const Expanded(
                                  child: Text(
                                    'آخر نبض مسجل',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: NabadColors.deepTeal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: heartRate,
                                    style: const TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      color: NabadColors.primary,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' نبضة/دقيقة',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: NabadColors.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            CustomPaint(
                              size: const Size(double.infinity, 32),
                              painter: _WavePainter(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC9F3F8),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: NabadColors.primary,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'الحساسية',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: NabadColors.deepTeal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  allergies,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: NabadColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC9F3F8),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.monitor_heart_outlined,
                                      color: NabadColors.primary,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    const Expanded(
                                      child: Text(
                                        'الأمراض المزمنة',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: NabadColors.deepTeal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  diseases,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: NabadColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ─── Appointment + Pill Reminder ──────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: BlocBuilder<AppointmentCubit, AppointmentState>(
                        builder: (context, appointmentState) {
                          final appointment = context
                              .read<AppointmentCubit>()
                              .nextUpcoming;
                          final reminder =
                              appointmentState is AppointmentLoading
                              ? 'جاري تحميل الموعد...'
                              : appointmentState is AppointmentError
                              ? 'تعذر تحميل الموعد'
                              : appointment == null
                              ? 'لا يوجد موعد قادم'
                              : _appointmentReminder(appointment);

                          return _ActionCard(
                            icon: Icons.calendar_today_outlined,
                            label: 'موعدي القادم',
                            sub: reminder,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child:
                          BlocBuilder<
                            MedicineReminderCubit,
                            MedicineReminderState
                          >(
                            builder: (context, reminderState) {
                              final active = reminderState.reminders
                                  .where((item) => item.enabled)
                                  .length;
                              return _ActionCard(
                                icon: Icons.medication_outlined,
                                label: 'تذكير دواء',
                                sub: active == 0
                                    ? 'أضف تذكيراً'
                                    : '$active تذكير نشط',
                                btnText: active == 0 ? 'إضافة' : 'إدارة',
                                btnColor: NabadColors.primary,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.medicineReminders,
                                ),
                              );
                            },
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ─── المعلومات الطبية ─────────────────────────────────────
                const _SectionTitle(title: 'المعلومات الطبية'),
                const SizedBox(height: 12),
                _InfoCard(
                  children: [
                    _InfoRow(
                      icon: Icons.bloodtype_rounded,
                      iconColor: const Color(0xFFE05C5C),
                      label: 'زمرة الدم',
                      value: _bloodTypeLabel(latestBloodType),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    const Expanded(
                      child: _SectionTitle(title: 'سجل الزيارات الطبية'),
                    ),
                    IconButton(
                      tooltip: 'تحديث الملف الطبي',
                      onPressed:
                          medicalState.status ==
                              PatientMedicalRecordStatus.loading
                          ? null
                          : () => context
                                .read<PatientMedicalRecordCubit>()
                                .loadMedicalFile(),
                      icon: const Icon(Icons.refresh_rounded),
                      color: NabadColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _MedicalRecordsSection(state: medicalState),

                const SizedBox(height: 24),

                _menuItem(
                  context,
                  Icons.person_outline_rounded,
                  'المعلومات الشخصية',
                  () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          _PersonalInformationPage(patient: patient),
                    ),
                  ),
                ),
                _menuItem(
                  context,
                  Icons.account_balance_wallet_outlined,
                  'محفظتي',
                  () => Navigator.pushNamed(context, AppRoutes.wallet),
                ),
                _menuItem(
                  context,
                  Icons.settings_outlined,
                  'الإعدادات',
                  () => Navigator.pushNamed(context, AppRoutes.patientSettings),
                ),

                const SizedBox(height: 20),

                // ─── زر تسجيل الخروج ──────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmLogout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFEDED),
                      foregroundColor: const Color(0xFFE05C5C),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFC9F3F8),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: NabadColors.primary, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: colors.onSurface,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: NabadColors.mutedText),
      onTap: onTap,
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFC9F3F8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: NabadColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'هل تريد الخروج؟',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: NabadColors.darkText,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'ستحتاج لتسجيل الدخول مجدداً.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: NabadColors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: NabadColors.primary.withAlpha(60),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'إلغاء',
                        style: TextStyle(
                          color: NabadColors.deepTeal,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<UserCubit>().logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NabadColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'خروج',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonalInformationPage extends StatelessWidget {
  final PatientModel patient;

  const _PersonalInformationPage({required this.patient});

  @override
  Widget build(BuildContext context) {
    final user = patient.user;
    final fullName = '${user.firstName} ${user.lastName}'.trim();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: NabadColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'المعلومات الشخصية',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: NabadColors.primary,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isEmpty ? 'المريض' : fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'بيانات الحساب الشخصية',
                          style: TextStyle(
                            color: Color(0xDFFFFFFF),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'البيانات الشخصية'),
            const SizedBox(height: 12),
            _InfoCard(
              children: [
                _InfoRow(
                  icon: Icons.wc_rounded,
                  label: 'الجنس',
                  value: _personalGenderLabel(patient.gender),
                ),
                const _Divider(),
                _InfoRow(
                  icon: Icons.cake_rounded,
                  label: 'تاريخ الميلاد',
                  value: _formatPersonalDate(patient.birthDate),
                ),
                const _Divider(),
                _InfoRow(
                  icon: Icons.location_on_rounded,
                  label: 'العنوان',
                  value: _personalValue(patient.address),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'معلومات التواصل'),
            const SizedBox(height: 12),
            _InfoCard(
              children: [
                _InfoRow(
                  icon: Icons.phone_rounded,
                  label: 'رقم الهاتف',
                  value: _personalValue(user.phone),
                ),
                const _Divider(),
                _InfoRow(
                  icon: Icons.email_rounded,
                  label: 'البريد الإلكتروني',
                  value: _personalValue(user.email),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'حالة الحساب'),
            const SizedBox(height: 12),
            _InfoCard(
              children: [
                _InfoRow(
                  icon: user.emailVerifiedAt != null
                      ? Icons.verified_rounded
                      : Icons.pending_rounded,
                  iconColor: user.emailVerifiedAt != null
                      ? const Color(0xFF3BB55E)
                      : Colors.orange,
                  label: 'حالة البريد الإلكتروني',
                  value: user.emailVerifiedAt != null
                      ? 'تم التحقق'
                      : 'لم يتم التحقق بعد',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _personalGenderLabel(String? gender) {
  final value = gender?.trim() ?? '';
  if (value.isEmpty) return 'غير محدد';
  if (value == 'male' || value == 'ذكر') return 'ذكر';
  if (value == 'female' || value == 'أنثى') return 'أنثى';
  return value;
}

String _personalValue(String? value) {
  final normalized = value?.trim() ?? '';
  return normalized.isEmpty ? 'غير محدد' : normalized;
}

String _formatPersonalDate(String? value) {
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty) return 'غير محدد';
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) return normalized;
  return '${parsed.year.toString().padLeft(4, '0')}-'
      '${parsed.month.toString().padLeft(2, '0')}-'
      '${parsed.day.toString().padLeft(2, '0')}';
}

class _MedicalRecordsSection extends StatelessWidget {
  final PatientMedicalRecordState state;

  const _MedicalRecordsSection({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.status == PatientMedicalRecordStatus.loading &&
        state.records.isEmpty) {
      return const _MedicalMessage(
        icon: Icons.sync_rounded,
        message: 'جاري تحميل السجل الطبي...',
        loading: true,
      );
    }
    if (state.status == PatientMedicalRecordStatus.failure &&
        state.records.isEmpty) {
      return _MedicalMessage(
        icon: Icons.cloud_off_rounded,
        message: state.errorMessage ?? 'تعذر تحميل السجل الطبي.',
        actionLabel: 'إعادة المحاولة',
        onAction: () =>
            context.read<PatientMedicalRecordCubit>().loadMedicalFile(),
      );
    }
    if (state.records.isEmpty) {
      return const _MedicalMessage(
        icon: Icons.folder_open_rounded,
        message: 'لا توجد زيارات طبية مسجلة حتى الآن.',
      );
    }

    return Column(
      children: [
        if (state.status == PatientMedicalRecordStatus.loading)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (state.status == PatientMedicalRecordStatus.failure)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              state.errorMessage ?? 'تعذر تحديث الملف الطبي.',
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        ...state.records.map(
          (record) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MedicalRecordCard(record: record),
          ),
        ),
      ],
    );
  }
}

class _MedicalRecordCard extends StatelessWidget {
  final PatientMedicalRecord record;

  const _MedicalRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFC9F3F8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.medical_information_rounded,
            color: NabadColors.primary,
          ),
        ),
        title: Text(
          record.diagnosis,
          style: const TextStyle(
            color: NabadColors.darkText,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          '${record.doctorName} • ${_formatMedicalDate(record.date)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: NabadColors.mutedText,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          const Divider(height: 12),
          _RecordDetail(
            icon: Icons.monitor_heart_outlined,
            label: 'نبض القلب',
            value: record.heartRate == null
                ? 'غير مسجل'
                : '${record.heartRate} نبضة/دقيقة',
          ),
          _RecordDetail(
            icon: Icons.bloodtype_outlined,
            label: 'زمرة الدم',
            value: _valueOrFallback(record.bloodType),
          ),
          _RecordDetail(
            icon: Icons.warning_amber_rounded,
            label: 'الحساسية',
            value: _valueOrFallback(record.allergies),
          ),
          _RecordDetail(
            icon: Icons.healing_outlined,
            label: 'الأمراض والحالات السابقة',
            value: _valueOrFallback(record.diseases),
          ),
          _RecordDetail(
            icon: Icons.notes_rounded,
            label: 'ملاحظات الطبيب',
            value: _valueOrFallback(record.notes),
          ),
          if (record.referredToLaboratory)
            _RecordDetail(
              icon: Icons.biotech_outlined,
              label: 'إحالة المختبر والتحاليل المطلوبة',
              value: record.laboratoryNotes.isEmpty
                  ? 'تمت الإحالة إلى المختبر'
                  : record.laboratoryNotes,
              highlighted: true,
            ),
          if (record.referredToPharmacist && record.prescription == null)
            const _RecordDetail(
              icon: Icons.local_pharmacy_outlined,
              label: 'إحالة الصيدلية',
              value: 'تمت الإحالة إلى الصيدلي',
              highlighted: true,
            ),
          if (record.prescription != null)
            _PrescriptionDetails(prescription: record.prescription!),
        ],
      ),
    );
  }
}

class _RecordDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlighted;

  const _RecordDetail({
    required this.icon,
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xFFC9F3F8).withAlpha(130)
            : const Color(0xFFF8FBFB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: NabadColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: NabadColors.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: NabadColors.darkText,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
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

class _PrescriptionDetails extends StatelessWidget {
  final PatientPrescription prescription;

  const _PrescriptionDetails({required this.prescription});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NabadColors.primary.withAlpha(35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.medication_outlined,
                color: NabadColors.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'الوصفة الطبية',
                style: TextStyle(
                  color: NabadColors.deepTeal,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (prescription.instructions.isNotEmpty)
            _PrescriptionText(
              label: 'التعليمات',
              value: prescription.instructions,
            ),
          if (prescription.notes.isNotEmpty)
            _PrescriptionText(label: 'ملاحظات', value: prescription.notes),
          if (prescription.items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'لا توجد أدوية مسجلة ضمن هذه الوصفة.',
                style: TextStyle(color: NabadColors.mutedText, fontSize: 12),
              ),
            )
          else
            ...prescription.items.map(
              (item) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: NabadColors.darkText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (item.dosage.isNotEmpty) 'الجرعة: ${item.dosage}',
                        if (item.frequency.isNotEmpty)
                          'التكرار: ${item.frequency}',
                        if (item.duration.isNotEmpty) 'المدة: ${item.duration}',
                        if (item.notes.isNotEmpty) 'ملاحظات: ${item.notes}',
                      ].join(' • '),
                      style: const TextStyle(
                        color: NabadColors.mutedText,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PrescriptionText extends StatelessWidget {
  final String label;
  final String value;

  const _PrescriptionText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: NabadColors.darkText,
          fontSize: 12.5,
          height: 1.4,
        ),
      ),
    );
  }
}

class _MedicalMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MedicalMessage({
    required this.icon,
    required this.message,
    this.loading = false,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          loading
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Icon(icon, color: NabadColors.primary, size: 32),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: NabadColors.mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

String _valueOrFallback(String value) =>
    value.trim().isEmpty ? 'غير مسجل' : value.trim();

String _formatMedicalDate(String value) {
  if (value.trim().isEmpty) return 'تاريخ غير محدد';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value.split('T').first;
  return '${parsed.year.toString().padLeft(4, '0')}-'
      '${parsed.month.toString().padLeft(2, '0')}-'
      '${parsed.day.toString().padLeft(2, '0')}';
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final String? btnText;
  final Color? btnColor;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.sub,
    this.btnText,
    this.btnColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: dark
            ? Theme.of(context).colorScheme.surface
            : const Color(0xFFC9F3F8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: NabadColors.primary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: dark
                        ? Theme.of(context).colorScheme.onSurface
                        : NabadColors.deepTeal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: NabadColors.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (btnText != null && onTap != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnColor ?? NabadColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  btnText!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
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

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NabadColors.primary.withAlpha(160)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, size.height / 2);
    path.lineTo(size.width * 0.15, size.height / 2);
    path.lineTo(size.width * 0.25, size.height * 0.1);
    path.lineTo(size.width * 0.35, size.height * 0.9);
    path.lineTo(size.width * 0.45, size.height / 2);
    path.lineTo(size.width * 0.60, size.height / 2);
    path.lineTo(size.width * 0.70, size.height * 0.25);
    path.lineTo(size.width * 0.80, size.height / 2);
    path.lineTo(size.width, size.height / 2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 17,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: NabadColors.primary.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? NabadColors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: NabadColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: NabadColors.darkText,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: NabadColors.primary.withAlpha(12),
      indent: 36,
    );
  }
}
