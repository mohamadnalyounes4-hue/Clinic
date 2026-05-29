import 'package:flutter/material.dart';
import 'package:nabad/core/theme/nabad_colors.dart';
import 'package:nabad/widgets/soft_ring.dart';

class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({super.key});

  @override
  State<DoctorHomePage> createState() => _DoctorHomePageState();
}

class _DoctorHomePageState extends State<DoctorHomePage> {
  int _selectedIndex = 0;

  final List<_Appointment> _appointments = const [
    _Appointment(
      patientName: 'ليان محمود',
      time: '09:30',
      type: 'متابعة',
      status: 'بانتظارك',
      accentColor: Color(0xFF007782),
    ),
    _Appointment(
      patientName: 'أحمد الخطيب',
      time: '10:15',
      type: 'استشارة',
      status: 'مؤكد',
      accentColor: Color(0xFF2F80ED),
    ),
    _Appointment(
      patientName: 'سارة عثمان',
      time: '11:00',
      type: 'قراءة تحاليل',
      status: 'ملف جاهز',
      accentColor: Color(0xFFE2A228),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: NabadColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned(top: 80, right: -72, child: SoftRing(size: 220)),
              Positioned(
                left: -48,
                bottom: 130,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.05,
                    child: Image.asset(
                      'assets/images/logoIcon.png',
                      width: 210,
                      height: 210,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  const _DoctorHeader(),
                  const SizedBox(height: 18),
                  const _TodayOverview(),
                  const SizedBox(height: 18),
                  _NextAppointment(appointment: _appointments.first),
                  const SizedBox(height: 18),
                  const _SectionHeader(
                    title: 'خدمات الطبيب',
                    actionLabel: 'إدارة',
                  ),
                  const SizedBox(height: 10),
                  const _FeatureGrid(),
                  const SizedBox(height: 20),
                  const _SectionHeader(
                    title: 'مواعيد اليوم',
                    actionLabel: 'عرض الكل',
                  ),
                  const SizedBox(height: 10),
                  ..._appointments.map(
                    (appointment) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AppointmentTile(appointment: appointment),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: _DoctorBottomBar(
          selectedIndex: _selectedIndex,
          onChanged: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }
}

class _DoctorHeader extends StatelessWidget {
  const _DoctorHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: NabadColors.primary.withAlpha(24)),
          ),
          child: const Icon(
            Icons.medical_services_rounded,
            color: NabadColors.primary,
            size: 29,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'صباح الخير، د. سامر',
                style: TextStyle(
                  color: NabadColors.darkText,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'لديك جدول عيادة نشط اليوم',
                style: TextStyle(
                  color: NabadColors.mutedText,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
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
          icon: const Icon(Icons.notifications_rounded),
        ),
      ],
    );
  }
}

class _TodayOverview extends StatelessWidget {
  const _TodayOverview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: NabadColors.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: NabadColors.primary.withAlpha(38),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ملخص اليوم',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(42),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'الثلاثاء',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: _OverviewMetric(
                  value: '12',
                  label: 'موعد',
                  icon: Icons.calendar_month_rounded,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _OverviewMetric(
                  value: '3',
                  label: 'تحاليل',
                  icon: Icons.science_rounded,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _OverviewMetric(
                  value: '5',
                  label: 'ملفات',
                  icon: Icons.folder_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _OverviewMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(235),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: NabadColors.primary, size: 22),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: NabadColors.deepTeal,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: NabadColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextAppointment extends StatelessWidget {
  final _Appointment appointment;

  const _NextAppointment({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(238),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: NabadColors.primary.withAlpha(18)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: NabadColors.softTeal,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person_search_rounded,
              color: NabadColors.primary,
              size: 29,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'المريض القادم',
                  style: TextStyle(
                    color: NabadColors.mutedText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  appointment.patientName,
                  style: const TextStyle(
                    color: NabadColors.darkText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${appointment.type} - ${appointment.time}',
                  style: const TextStyle(
                    color: NabadColors.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: () {},
            style: IconButton.styleFrom(
              backgroundColor: NabadColors.primary,
              foregroundColor: Colors.white,
              fixedSize: const Size(46, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;

  const _SectionHeader({required this.title, required this.actionLabel});

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
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: NabadColors.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  static const List<_DoctorFeature> _features = [
    _DoctorFeature(
      title: 'جدول المواعيد',
      subtitle: 'متابعة الحجوزات',
      icon: Icons.event_available_rounded,
      color: Color(0xFF007782),
    ),
    _DoctorFeature(
      title: 'ملفات المرضى',
      subtitle: 'سجل طبي سريع',
      icon: Icons.folder_shared_rounded,
      color: Color(0xFF2F80ED),
    ),
    _DoctorFeature(
      title: 'الوصفات',
      subtitle: 'كتابة وصفة',
      icon: Icons.edit_note_rounded,
      color: Color(0xFF8A5CF6),
    ),
    _DoctorFeature(
      title: 'التحاليل',
      subtitle: 'نتائج تحتاج مراجعة',
      icon: Icons.biotech_rounded,
      color: Color(0xFFE2A228),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: _features.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        return _FeatureTile(feature: _features[index]);
      },
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final _DoctorFeature feature;

  const _FeatureTile({required this.feature});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(238),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: feature.color.withAlpha(25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: feature.color.withAlpha(24),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(feature.icon, color: feature.color, size: 22),
            ),
            const Spacer(),
            Text(
              feature.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: NabadColors.darkText,
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              feature.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: NabadColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final _Appointment appointment;

  const _AppointmentTile({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(238),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: NabadColors.primary.withAlpha(16)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: appointment.accentColor.withAlpha(22),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              appointment.time,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: appointment.accentColor,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.patientName,
                  style: const TextStyle(
                    color: NabadColors.darkText,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  appointment.type,
                  style: const TextStyle(
                    color: NabadColors.mutedText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: appointment.accentColor.withAlpha(20),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              appointment.status,
              style: TextStyle(
                color: appointment.accentColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorBottomBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _DoctorBottomBar({
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = const [
      _BottomItem(icon: Icons.home_rounded, label: 'الرئيسية'),
      _BottomItem(icon: Icons.calendar_month_rounded, label: 'المواعيد'),
      _BottomItem(icon: Icons.groups_rounded, label: 'المرضى'),
      _BottomItem(icon: Icons.person_rounded, label: 'الحساب'),
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
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? NabadColors.primary.withAlpha(18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  item.icon,
                  color: isSelected
                      ? NabadColors.primary
                      : NabadColors.mutedText,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _Appointment {
  final String patientName;
  final String time;
  final String type;
  final String status;
  final Color accentColor;

  const _Appointment({
    required this.patientName,
    required this.time,
    required this.type,
    required this.status,
    required this.accentColor,
  });
}

class _DoctorFeature {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _DoctorFeature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class _BottomItem {
  final IconData icon;
  final String label;

  const _BottomItem({required this.icon, required this.label});
}
