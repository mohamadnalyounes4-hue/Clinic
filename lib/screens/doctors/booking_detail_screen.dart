import 'package:flutter/material.dart';
import '../../Models/doctor_directory_model.dart';
import '../../core/theme/nabd_colors.dart';

class BookingDetailScreen extends StatefulWidget {
  final Doctor doctor;

  const BookingDetailScreen({super.key, required this.doctor});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  // ── الحالة ──
  int _selectedDayIndex = 1; // الاثنين افتراضياً
  String _selectedTime = '09:00';
  bool _isMorning = true;

  // ── بيانات الأيام ──
  final List<Map<String, String>> _days = [
    {'name': 'الأحد', 'num': '15'},
    {'name': 'الاثنين', 'num': '16'},
    {'name': 'الثلاثاء', 'num': '17'},
    {'name': 'الأربعاء', 'num': '18'},
    {'name': 'الخميس', 'num': '19'},
  ];

  // ── أوقات الصباح ──
  final List<Map<String, dynamic>> _morningSlots = [
    {'time': '09:00', 'label': 'صباحاً', 'booked': false},
    {'time': '09:30', 'label': 'صباحاً', 'booked': false},
    {'time': '10:00', 'label': 'صباحاً', 'booked': false},
    {'time': '10:30', 'label': 'صباحاً', 'booked': false},
    {'time': '11:00', 'label': 'محجوز', 'booked': true},
    {'time': '11:30', 'label': 'صباحاً', 'booked': false},
  ];

  // ── أوقات المساء ──
  final List<Map<String, dynamic>> _eveningSlots = [
    {'time': '04:00', 'label': 'مساءً', 'booked': false},
    {'time': '04:30', 'label': 'مساءً', 'booked': false},
    {'time': '05:00', 'label': 'مساءً', 'booked': false},
    {'time': '05:30', 'label': 'مساءً', 'booked': false},
    {'time': '06:00', 'label': 'محجوز', 'booked': true},
    {'time': '06:30', 'label': 'مساءً', 'booked': false},
  ];

  List<Map<String, dynamic>> get _currentSlots =>
      _isMorning ? _morningSlots : _eveningSlots;

  String get _selectedDayName => _days[_selectedDayIndex]['name']!;
  String get _selectedDayNum => _days[_selectedDayIndex]['num']!;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: NabadColors.background,
        bottomNavigationBar: _buildConfirmBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // ── Header ──
                _buildHeader(context),
                const SizedBox(height: 20),

                // ── بطاقة الطبيب ──
                _buildDoctorCard(),
                const SizedBox(height: 24),

                // ── اختيار التاريخ ──
                _buildDateSection(),
                const SizedBox(height: 24),

                // ── الفترات المتاحة ──
                _buildTimeSection(),
                const SizedBox(height: 24),

                // ── ملاحظة طبية ──
                _buildMedicalNote(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // جرس الإشعارات
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: NabadColors.white,
            boxShadow: [
              BoxShadow(
                color: NabadColors.primary.withOpacity(0.08),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_outlined,
            color: NabadColors.darkText,
            size: 20,
          ),
        ),

        // العنوان + زر الرجوع
        Row(
          children: [
            const Text(
              'نبض',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: NabadColors.darkText,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: NabadColors.darkText,
                size: 26,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── بطاقة الطبيب ──
  Widget _buildDoctorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NabadColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: NabadColors.primary.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          // أيقونة الرسالة
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: NabadColors.softTeal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: NabadColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // الاسم والتخصص والتقييم
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.doctor.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: NabadColors.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.doctor.specialty,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    color: NabadColors.mutedText,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '(2.4k تقييم)',
                      style: TextStyle(
                        fontSize: 11,
                        color: NabadColors.mutedText.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.doctor.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: NabadColors.darkText,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.star_rounded,
                      color: NabadColors.starColor,
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // صورة الطبيب + شارة متاح
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _doctorImage(),
              ),
              Positioned(
                bottom: -6,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: NabadColors.primary,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Text(
                      'متاح',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: NabadColors.white,
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

  Widget _doctorImage() {
    final imagePath = widget.doctor.imagePath;
    final isNetworkImage = imagePath.startsWith('http');

    if (isNetworkImage) {
      return Image.network(
        imagePath,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _doctorImageFallback(),
      );
    }

    return Image.asset(
      imagePath,
      width: 72,
      height: 72,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _doctorImageFallback(),
    );
  }

  Widget _doctorImageFallback() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: NabadColors.softTeal,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: NabadColors.primary,
        size: 36,
      ),
    );
  }

  // ── اختيار التاريخ ──
  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // العنوان + الشهر
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // الشهر + سهم
            GestureDetector(
              onTap: () {},
              child: Row(
                children: [
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: NabadColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'مارس 2025',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: NabadColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'اختر التاريخ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: NabadColors.darkText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // أيام الأسبوع
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_days.length, (index) {
            // عكس الترتيب لـ RTL
            final i = _days.length - 1 - index;
            final isSelected = _selectedDayIndex == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedDayIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? NabadColors.primary : NabadColors.white,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: isSelected
                      ? []
                      : [
                          BoxShadow(
                            color: NabadColors.primary.withOpacity(0.06),
                            blurRadius: 8,
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    Text(
                      _days[i]['name']!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? NabadColors.white
                            : NabadColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _days[i]['num']!,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? NabadColors.white
                            : NabadColors.darkText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── الفترات المتاحة ──
  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // العنوان + تبديل صباح/مساء
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // زرا الصباح والمساء
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: NabadColors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: NabadColors.divider),
              ),
              child: Row(
                children: [
                  _periodTab('المسائية', false),
                  _periodTab('الصباحية', true),
                ],
              ),
            ),
            const Text(
              'الفترات المتاحة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: NabadColors.darkText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // شبكة الأوقات
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
          ),
          itemCount: _currentSlots.length,
          itemBuilder: (context, index) {
            final slot = _currentSlots[index];
            final isBooked = slot['booked'] as bool;
            final time = slot['time'] as String;
            final label = slot['label'] as String;
            final isSelected = _selectedTime == time && !isBooked;

            return GestureDetector(
              onTap: isBooked
                  ? null
                  : () => setState(() => _selectedTime = time),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected ? NabadColors.softTeal : NabadColors.white,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: isSelected
                        ? NabadColors.primary
                        : NabadColors.divider,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isBooked
                            ? NabadColors.mutedText
                            : isSelected
                            ? NabadColors.primary
                            : NabadColors.darkText,
                        decoration: isBooked
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: isBooked
                            ? NabadColors.mutedText
                            : NabadColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _periodTab(String label, bool isMorning) {
    final isSelected = _isMorning == isMorning;
    return GestureDetector(
      onTap: () => setState(() => _isMorning = isMorning),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? NabadColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? NabadColors.white : NabadColors.mutedText,
          ),
        ),
      ),
    );
  }

  // ── ملاحظة طبية ──
  Widget _buildMedicalNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NabadColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NabadColors.divider),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: NabadColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text(
                  'ملاحظة طبية',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: NabadColors.darkText,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'يرجى إحضار التقارير الطبية السابقة إذا كانت متوفرة.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    color: NabadColors.mutedText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── شريط التأكيد السفلي ──
  Widget _buildConfirmBar() {
    final period = _isMorning ? 'ص' : 'م';
    // final dayLabel = '$_selectedDayNum مارس، $_selectedTime $period';
    final dayLabel =
        '$_selectedDayName $_selectedDayNum مارس، $_selectedTime $period';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: NabadColors.white,
        boxShadow: [
          BoxShadow(
            color: NabadColors.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // السعر والتاريخ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // التاريخ المختار
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'التاريخ المختار',
                    style: TextStyle(
                      fontSize: 11,
                      color: NabadColors.mutedText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    dayLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: NabadColors.darkText,
                    ),
                  ),
                ],
              ),
              // السعر
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'قيمة الكشف',
                    style: TextStyle(
                      fontSize: 11,
                      color: NabadColors.mutedText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${widget.doctor.price.toInt()} ر.س',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: NabadColors.darkText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // زر التأكيد
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _confirmBooking(),
              icon: const Icon(Icons.calendar_month_rounded, size: 18),
              label: const Text('تأكيد الحجز'),
              style: ElevatedButton.styleFrom(
                backgroundColor: NabadColors.primary,
                foregroundColor: NabadColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmBooking() {
    final period = _isMorning ? 'صباحاً' : 'مساءً';
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: NabadColors.softTeal,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: NabadColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'تم الحجز بنجاح!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: NabadColors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'موعدك مع ${widget.doctor.name}\n$_selectedDayNum مارس الساعة $_selectedTime $period',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: NabadColors.mutedText,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: NabadColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: const Text(
                  'حسناً',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
