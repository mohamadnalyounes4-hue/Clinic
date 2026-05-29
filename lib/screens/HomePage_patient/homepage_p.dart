import 'package:flutter/material.dart';
import 'package:nabad/core/theme/nabad_colors.dart';
import 'package:nabad/widgets/soft_ring.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  int _selectedIndex = 0;

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

  final List<_Specialty> _specialties = const [
    _Specialty(label: 'القلب', icon: Icons.favorite_border_rounded),
    _Specialty(label: 'الأسنان', icon: Icons.health_and_safety_rounded),
    _Specialty(label: 'العيون', icon: Icons.remove_red_eye_outlined),
    _Specialty(label: 'الجلدية', icon: Icons.spa_outlined),
  ];

  final List<_SuggestedDoctor> _doctors = const [
    _SuggestedDoctor(
      name: 'د. خالد الروبي',
      specialty: 'استشاري جراحة العظام',
      image: 'assets/images/Male.jpg',
      rating: '4.8',
      reviews: '120 مراجعة',
    ),
    _SuggestedDoctor(
      name: 'د. مريم القحطاني',
      specialty: 'أخصائية طب العائلة',
      image: 'assets/images/Female.jpg',
      rating: '4.7',
      reviews: '98 مراجعة',
    ),
    _SuggestedDoctor(
      name: 'د. أحمد سليمان',
      specialty: 'استشاري طب العيون',
      image: 'assets/images/4.jpg',
      rating: '4.9',
      reviews: '154 مراجعة',
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
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  const _PatientHeader(),
                  const SizedBox(height: 18),
                  const _SearchBox(),
                  const SizedBox(height: 20),
                  _TipsCarousel(tips: _tips),
                  const SizedBox(height: 22),
                  const _SectionHeader(
                    title: 'المواعيد القادمة',
                    action: 'الكل',
                  ),
                  const SizedBox(height: 10),
                  const _UpcomingAppointmentCard(),
                  const SizedBox(height: 22),
                  const _SectionHeader(title: 'التخصصات الطبية'),
                  const SizedBox(height: 12),
                  _SpecialtyRow(specialties: _specialties),
                  const SizedBox(height: 22),
                  const _SectionHeader(
                    title: 'أطباء مقترحون',
                    action: 'عرض الكل',
                  ),
                  const SizedBox(height: 10),
                  ..._doctors.map(
                    (doctor) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SuggestedDoctorCard(doctor: doctor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          backgroundColor: NabadColors.primary,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 30),
        ),
        bottomNavigationBar: _PatientBottomBar(
          selectedIndex: _selectedIndex,
          onChanged: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }
}

class _PatientHeader extends StatelessWidget {
  const _PatientHeader();

  @override
  Widget build(BuildContext context) {
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
        const Text(
          'Nabdh',
          style: TextStyle(
            color: NabadColors.primary,
            fontSize: 28,
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
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return _TipCard(tip: tips[index]);
        },
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

class _SpecialtyRow extends StatelessWidget {
  final List<_Specialty> specialties;

  const _SpecialtyRow({required this.specialties});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: specialties.map((specialty) {
        return Expanded(child: _SpecialtyTile(specialty: specialty));
      }).toList(),
    );
  }
}

class _SpecialtyTile extends StatelessWidget {
  final _Specialty specialty;

  const _SpecialtyTile({required this.specialty});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(22),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFC9F3F8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(specialty.icon, color: NabadColors.primary, size: 30),
          ),
          const SizedBox(height: 9),
          Text(
            specialty.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: NabadColors.deepTeal,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestedDoctorCard extends StatelessWidget {
  final _SuggestedDoctor doctor;

  const _SuggestedDoctorCard({required this.doctor});

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
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              doctor.image,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
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
                  doctor.specialty,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: NabadColors.mutedText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFE2A228),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      doctor.rating,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: Color(0xFFE2A228),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        doctor.reviews,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: NabadColors.mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
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
    final items = const [
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

class _Specialty {
  final String label;
  final IconData icon;

  const _Specialty({required this.label, required this.icon});
}

class _SuggestedDoctor {
  final String name;
  final String specialty;
  final String image;
  final String rating;
  final String reviews;

  const _SuggestedDoctor({
    required this.name,
    required this.specialty,
    required this.image,
    required this.rating,
    required this.reviews,
  });
}

class _BottomItem {
  final IconData icon;
  final String label;

  const _BottomItem({required this.icon, required this.label});
}
