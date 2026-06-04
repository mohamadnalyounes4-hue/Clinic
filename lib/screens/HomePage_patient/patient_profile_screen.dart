import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/user_cubit.dart';
import 'package:nabad/Cubits/user_state.dart';
import 'package:nabad/Models/patient_model.dart';
import 'package:nabad/core/router/app_router.dart';
import 'package:nabad/core/theme/nabad_colors.dart';

class PatientProfileScreen extends StatelessWidget {
  const PatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFB), 
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
            return _ProfileContent(patient: state.patient);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ProfileContent extends StatelessWidget {
  final PatientModel patient;
  const _ProfileContent({required this.patient});

  String _bloodTypeLabel(String? bt) =>
      (bt == null || bt.isEmpty) ? 'غير محدد' : bt.toUpperCase();

  String _genderLabel(String? g) {
    if (g == null) return 'غير محدد';
    if (g == 'male' || g == 'ذكر') return 'ذكر';
    if (g == 'female' || g == 'أنثى') return 'أنثى';
    return g;
  }

  String _formatDate(String? d) {
    if (d == null || d.isEmpty) return 'غير محدد';
    try {
      final parts = d.split('-');
      if (parts.length != 3) return d;
      const months = [
        '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
      ];
      final month = int.tryParse(parts[1]) ?? 0;
      return '${parts[2]} ${months[month]} ${parts[0]}';
    } catch (_) {
      return d;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = patient.user;
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
                                const Text(
                                  'Heart Rate',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: NabadColors.deepTeal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: '72',
                                    style: TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      color: NabadColors.primary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' b/m',
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
                                      Icons.water_drop_outlined,
                                      color: NabadColors.primary,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Blood Sugar',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: NabadColors.deepTeal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  '90 mg/dL',
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
                                    const Text(
                                      'Blood Pressure',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: NabadColors.deepTeal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  '80/120',
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
                      child: _ActionCard(
                        icon: Icons.calendar_today_outlined,
                        label: 'موعدي',
                        sub: 'القادم',
                        btnText: 'إعادة جدولة',
                        btnColor: NabadColors.primary,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.medication_outlined,
                        label: 'تذكير دواء',
                        sub: 'أضف تذكيراً',
                        btnText: 'إضافة',
                        btnColor: NabadColors.primary,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ─── معلومات التواصل ──────────────────────────────────────
                const _SectionTitle(title: 'معلومات التواصل'),
                const SizedBox(height: 12),
                _InfoCard(
                  children: [
                    _InfoRow(
                      icon: Icons.phone_rounded,
                      label: 'رقم الهاتف',
                      value: user.phone,
                    ),
                    const _Divider(),
                    _InfoRow(
                      icon: Icons.email_rounded,
                      label: 'البريد الإلكتروني',
                      value: user.email,
                    ),
                    const _Divider(),
                    _InfoRow(
                      icon: Icons.location_on_rounded,
                      label: 'العنوان',
                      value: patient.address ?? 'غير محدد',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ─── المعلومات الطبية ─────────────────────────────────────
                const _SectionTitle(title: 'المعلومات الطبية'),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _MiniCard(
                        icon: Icons.bloodtype_rounded,
                        iconColor: const Color(0xFFE05C5C),
                        iconBg: const Color(0xFFFFEDED),
                        label: 'زمرة الدم',
                        value: _bloodTypeLabel(patient.bloodType),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniCard(
                        icon: Icons.wc_rounded,
                        iconColor: NabadColors.primary,
                        iconBg: const Color(0xFFC9F3F8),
                        label: 'الجنس',
                        value: _genderLabel(patient.gender),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  children: [
                    _InfoRow(
                      icon: Icons.cake_rounded,
                      label: 'تاريخ الميلاد',
                      value: _formatDate(patient.birthDate),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ─── الحساب ───────────────────────────────────────────────
                const _SectionTitle(title: 'الحساب'),
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
                      label: 'حالة البريد',
                      value: user.emailVerifiedAt != null
                          ? 'تم التحقق'
                          : 'لم يتم التحقق بعد',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _menuItem(Icons.receipt_long_outlined, 'طلباتي', () {}),
                _menuItem(Icons.biotech_outlined, 'تحاليلي', () {}),
                _menuItem(Icons.headset_mic_outlined, 'استشاراتي', () {}),
                _menuItem(Icons.history_rounded, 'سجل المدفوعات', () {}),
                _menuItem(Icons.settings_outlined, 'الإعدادات', () {}),

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

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
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
        style: const TextStyle(
          color: NabadColors.darkText,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
      // تم استبدالها بـ chevron_right لتتناسب منطقياً مع الواجهات العربية (RTL)
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

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final String btnText;
  final Color btnColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.sub,
    required this.btnText,
    required this.btnColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFC9F3F8),
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: NabadColors.deepTeal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 11,
              color: NabadColors.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                padding: const EdgeInsets.symmetric(vertical: 7),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                btnText,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
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
      style: const TextStyle(
        color: NabadColors.darkText,
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
        color: Colors.white,
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

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  const _MiniCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: NabadColors.primary.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: NabadColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: NabadColors.darkText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}