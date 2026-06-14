import 'package:flutter/material.dart';
import 'package:nabad/Models/doctor_directory_model.dart';
import 'package:nabad/Models/doctor_model.dart';
import 'package:nabad/core/theme/nabad_colors.dart';
import 'package:nabad/screens/doctors/booking_detail_screen.dart';

class DoctorProfileBookingScreen extends StatelessWidget {
  final DoctorModel doctor;

  const DoctorProfileBookingScreen({super.key, required this.doctor});

  String get _doctorName => 'د. ${doctor.fullName}'.trim();

  String get _specialty =>
      (doctor.specialization == null || doctor.specialization!.trim().isEmpty)
      ? 'طبيب مختص'
      : doctor.specialization!.trim();

  int get _experience => doctor.yearsOfExperience ?? 0;

  String get _aboutText {
    final certificate = doctor.certificate?.trim();
    final experienceText = _experience > 0
        ? 'يمتلك خبرة تمتد لأكثر من $_experience سنوات في تقديم الرعاية الطبية ومتابعة الحالات بدقة.'
        : 'يمتلك خبرة واسعة في تقديم الرعاية الطبية ومتابعة الحالات بدقة.';

    if (certificate != null && certificate.isNotEmpty) {
      return '$_doctorName مختص في $_specialty، حاصل على $certificate. $experienceText يعمل على تقديم استشارات طبية واضحة وخطة علاج مناسبة لكل مريض.';
    }

    return '$_doctorName مختص في $_specialty. $experienceText يعمل على تقديم استشارات طبية واضحة وخطة علاج مناسبة لكل مريض.';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: NabadColors.background,
        bottomNavigationBar: _BookingBottomBar(
          price: 250,
          onBook: () => _openBookingDetails(context),
        ),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(onBack: () => Navigator.pop(context)),
                      const SizedBox(height: 20),
                      _HeroDoctorCard(doctor: doctor, doctorName: _doctorName),
                      const SizedBox(height: 60),
                      _AboutSection(text: _aboutText),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openBookingDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingDetailScreen(doctor: _bookingDoctor),
      ),
    );
  }

  Doctor get _bookingDoctor {
    return Doctor(
      id: doctor.id.toString(),
      name: _doctorName,
      specialty: _specialty,
      hospital: doctor.certificate?.trim().isNotEmpty == true
          ? doctor.certificate!.trim()
          : 'Nabad Clinic',
      rating: 4.9,
      price: 250,
      imagePath: doctor.profileImage ?? 'assets/images/Male.jpg',
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          color: NabadColors.primary,
        ),
        const Expanded(
          child: Text(
            'تفاصيل الطبيب',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: NabadColors.deepTeal,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.favorite_border_rounded),
          color: NabadColors.primary,
        ),
      ],
    );
  }
}

class _HeroDoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final String doctorName;

  const _HeroDoctorCard({required this.doctor, required this.doctorName});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 420,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: NabadColors.softTeal,
            boxShadow: [
              BoxShadow(
                color: NabadColors.primary.withAlpha(20),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _DoctorImage(doctor: doctor),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0xAA07535B),
                      Color(0x1107535B),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 42,
                child: Column(
                  children: [
                    Text(
                      doctorName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      doctor.specialization ?? 'طبيب مختص',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withAlpha(220),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: -48,
          child: Row(
            children: [
              const Expanded(
                child: _StatCard(
                  icon: Icons.groups_rounded,
                  value: '2k+',
                  label: 'مريض',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _StatCard(
                  icon: Icons.medical_services_outlined,
                  value: doctor.yearsOfExperience == null
                      ? 'خبرة'
                      : '${doctor.yearsOfExperience}+',
                  label: 'عام خبرة',
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: _StatCard(
                  icon: Icons.star_border_rounded,
                  value: '4.9',
                  label: 'تقييم',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DoctorImage extends StatelessWidget {
  final DoctorModel doctor;

  const _DoctorImage({required this.doctor});

  @override
  Widget build(BuildContext context) {
    if (doctor.profileImage != null) {
      return Image.network(
        doctor.profileImage!,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (context, error, stackTrace) =>
            _FallbackDoctorImage(doctor: doctor),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
      );
    }

    return _FallbackDoctorImage(doctor: doctor);
  }
}

class _FallbackDoctorImage extends StatelessWidget {
  final DoctorModel doctor;

  const _FallbackDoctorImage({required this.doctor});

  @override
  Widget build(BuildContext context) {
    final initials = doctor.fullName
        .trim()
        .split(' ')
        .take(2)
        .map((part) => part.isNotEmpty ? part[0] : '')
        .join();

    return Container(
      color: const Color(0xFFC9F3F8),
      child: Center(
        child: Container(
          width: 150,
          height: 150,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: NabadColors.primary,
                fontSize: 44,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 108),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: NabadColors.primary.withAlpha(22),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: NabadColors.primary, size: 22),
          const SizedBox(height: 5),
          Text(
            value,
            textDirection: TextDirection.ltr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: NabadColors.deepTeal,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: NabadColors.darkText,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final String text;

  const _AboutSection({required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const _SectionTitle(title: 'نبذة عن الطبيب'),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: NabadColors.darkText,
            fontSize: 14.5,
            height: 1.75,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: NabadColors.deepTeal,
        fontSize: 19,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _BookingBottomBar extends StatelessWidget {
  final int price;
  final VoidCallback onBook;

  const _BookingBottomBar({required this.price, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(245),
        boxShadow: [
          BoxShadow(
            color: NabadColors.primary.withAlpha(18),
            blurRadius: 24,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: onBook,
                icon: const Icon(Icons.calendar_today_outlined, size: 20),
                label: const Text('حجز موعد الآن'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NabadColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'سعر الاستشارة',
                  style: TextStyle(
                    color: NabadColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$price ريال',
                  style: const TextStyle(
                    color: NabadColors.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
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
