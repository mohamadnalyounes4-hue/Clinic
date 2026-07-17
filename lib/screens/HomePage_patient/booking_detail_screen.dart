import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/cubits/appointment_cubit.dart';
import 'package:nabad/Cubits/cubits/points_cubit.dart';
import 'package:nabad/Cubits/cubits/wallet_cubit.dart';
import '../../Cubits/states/points_state.dart';
import '../../Cubits/states/wallet_state.dart';
import '../../Models/doctor_model.dart';
import '../../Models/points_model.dart';
import '../../core/Error/exceptions.dart';
import '../../core/theme/nabd_colors.dart';

class BookingDetailScreen extends StatefulWidget {
  final DoctorModel doctor;

  const BookingDetailScreen({super.key, required this.doctor});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  // ── الحالة ──
  int _selectedDayIndex = 0; // اليوم الحالي افتراضياً
  String _selectedTime = '09:00';
  bool _isMorning = true;
  bool _isBooking = false;

  // ── النقاط المستخدمة كخصم ──
  int _pointsToRedeem = 0;

  @override
  void initState() {
    super.initState();
    context.read<PointsCubit>().getPointsSummary();
    context.read<WalletCubit>().loadWallet();
    _syncTimeSelection();
  }

  bool _isTimeInPast(DateTime day, String time) {
    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;
    if (!isToday) return false;

    final parts = time.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final slotDateTime = DateTime(day.year, day.month, day.day, h, m);
    return slotDateTime.isBefore(now.add(const Duration(minutes: 5)));
  }

  bool get _isSelectedTimeInPast => _isTimeInPast(_selectedDate, _selectedTime);

  void _syncTimeSelection() {
    final morningAvailable = _morningSlots.any(
      (s) => !_isTimeInPast(_selectedDate, s['time'] as String),
    );
    final eveningAvailable = _eveningSlots.any(
      (s) => !_isTimeInPast(_selectedDate, s['time'] as String),
    );

    if (_isMorning && !morningAvailable && eveningAvailable) {
      _isMorning = false;
    } else if (!_isMorning && !eveningAvailable && morningAvailable) {
      _isMorning = true;
    }

    final availableTimes = _currentSlots
        .map((s) => s['time'] as String)
        .where((t) => !_isTimeInPast(_selectedDate, t))
        .toList();
    if (availableTimes.isNotEmpty && !availableTimes.contains(_selectedTime)) {
      _selectedTime = availableTimes.first;
    }
  }

  // ── بيانات الأيام ──
  // بنعرض أقرب 6 أيام حقيقية من تاريخ اليوم. اختيار الوقت حر بالكامل
  // (مفيش ربط بدوام الطبيب حاليًا)، والباك هو اللي يرفض أي تعارض فعلي
  // وقت تأكيد الحجز.
  late final List<Map<String, dynamic>> _days = List.generate(6, (i) {
    final date = DateTime.now().add(Duration(days: i));
    return {
      'name': _weekdayName(date.weekday),
      'num': date.day.toString().padLeft(2, '0'),
      'date': date,
    };
  });

  String _weekdayName(int weekday) {
    const names = {
      1: 'الاثنين',
      2: 'الثلاثاء',
      3: 'الأربعاء',
      4: 'الخميس',
      5: 'الجمعة',
      6: 'السبت',
      7: 'الأحد',
    };
    return names[weekday] ?? '';
  }

  String _monthName(int month) {
    const names = {
      1: 'يناير', 2: 'فبراير', 3: 'مارس', 4: 'أبريل',
      5: 'مايو', 6: 'يونيو', 7: 'يوليو', 8: 'أغسطس',
      9: 'سبتمبر', 10: 'أكتوبر', 11: 'نوفمبر', 12: 'ديسمبر',
    };
    return names[month] ?? '';
  }

  // ── أوقات الصباح ──
  // ⚠️ مفيش endpoint يرجع الـ slots المحجوزة فعليًا للمريض، فبنعرض شبكة
  // أوقات ثابتة كل نص ساعة ونفلترها حسب دوام الطبيب بس (مش حسب حجوزات
  // فعلية). الباك هو اللي هيرفض أي تعارض وقت حقيقي عند التأكيد.
  final List<Map<String, dynamic>> _morningSlots = [
    {'time': '09:00', 'label': 'صباحاً'},
    {'time': '09:30', 'label': 'صباحاً'},
    {'time': '10:00', 'label': 'صباحاً'},
    {'time': '10:30', 'label': 'صباحاً'},
    {'time': '11:00', 'label': 'صباحاً'},
    {'time': '11:30', 'label': 'صباحاً'},
  ];

  // ── أوقات المساء ──
  // بصيغة 24 ساعة عشان تتبعت زي ما هي للباك (appointment_time بصيغة HH:mm).
  final List<Map<String, dynamic>> _eveningSlots = [
    {'time': '16:00', 'label': 'مساءً'},
    {'time': '16:30', 'label': 'مساءً'},
    {'time': '17:00', 'label': 'مساءً'},
    {'time': '17:30', 'label': 'مساءً'},
    {'time': '18:00', 'label': 'مساءً'},
    {'time': '18:30', 'label': 'مساءً'},
  ];

  List<Map<String, dynamic>> get _currentSlots =>
      _isMorning ? _morningSlots : _eveningSlots;

  String get _selectedDayName => _days[_selectedDayIndex]['name'] as String;
  String get _selectedDayNum => _days[_selectedDayIndex]['num'] as String;
  DateTime get _selectedDate => _days[_selectedDayIndex]['date'] as DateTime;

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

                // ── استخدام النقاط كخصم ──
                _buildPointsSection(),
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

  double get _consultationFee => widget.doctor.consultationFee ?? 0;

  PointsSummaryModel? get _pointsSummary {
    final state = context.read<PointsCubit>().state;
    return state is PointsSuccess ? state.summary : null;
  }

  double get _discountPercent =>
      _pointsSummary?.discountPercentFor(_pointsToRedeem) ?? 0;

  double get _discountAmount => _consultationFee * _discountPercent / 100;

  double get _finalPrice => _consultationFee - _discountAmount;

  double? get _walletBalance {
    final state = context.read<WalletCubit>().state;
    return state is WalletSuccess ? state.wallet.balance : null;
  }

  bool get _hasInsufficientBalance =>
      _walletBalance != null && _walletBalance! < _finalPrice;

  int _maxUsablePoints(PointsSummaryModel summary) {
    final byBalance = summary.pointsBalance;
    final byMaxDiscount = summary.pointsForMaxDiscount;
    final capped = byBalance < byMaxDiscount ? byBalance : byMaxDiscount;
    final unit = summary.pointsPerUnit;
    if (unit <= 0 || capped <= 0) return 0;
    // نقرّب لأسفل لأقرب مضاعف لوحدة النقاط عشان الخصم يطلع مظبوط بالمعادلة
    return (capped ~/ unit) * unit;
  }

  Widget _buildPointsSection() {
    return BlocBuilder<PointsCubit, PointsState>(
      builder: (context, state) {
        if (state is PointsLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (state is! PointsSuccess || !state.summary.loyaltyActive) {
          // النظام مش نشط أو تعذر التحميل → منخفيش القسم بدل ما نعطّل الحجز
          return const SizedBox.shrink();
        }

        final summary = state.summary;
        final maxUsable = _maxUsablePoints(summary);
        if (maxUsable <= 0) {
          // مفيش نقاط كفاية لأي خصم فعلي
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NabadColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: NabadColors.primary.withOpacity(0.06),
                blurRadius: 14,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _pointsToRedeem >= maxUsable
                            ? null
                            : () => setState(() {
                                _pointsToRedeem = (_pointsToRedeem +
                                        summary.pointsPerUnit)
                                    .clamp(0, maxUsable);
                              }),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        color: NabadColors.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '$_pointsToRedeem',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: NabadColors.darkText,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _pointsToRedeem <= 0
                            ? null
                            : () => setState(() {
                                _pointsToRedeem = (_pointsToRedeem -
                                        summary.pointsPerUnit)
                                    .clamp(0, maxUsable);
                              }),
                        icon: const Icon(
                          Icons.remove_circle_outline_rounded,
                        ),
                        color: NabadColors.mutedText,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const Text(
                    'استخدم نقاطك',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: NabadColors.darkText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'رصيدك: ${summary.pointsBalance} نقطة (كل ${summary.pointsPerUnit} نقطة = ${summary.discountPerUnit.toStringAsFixed(0)}% خصم، بحد أقصى ${summary.maxDiscountPercent.toStringAsFixed(0)}%)',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 11,
                  color: NabadColors.mutedText,
                  height: 1.5,
                ),
              ),
              if (_pointsToRedeem > 0) ...[
                const SizedBox(height: 10),
                const Divider(color: NabadColors.divider, height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '- ${_discountAmount.toStringAsFixed(0)} ر.س',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.green.shade700,
                      ),
                    ),
                    Text(
                      'خصم ${_discountPercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
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
                  'د. ${widget.doctor.fullName}'.trim(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: NabadColors.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (widget.doctor.specialization ?? '').trim().isEmpty
                      ? 'طبيب مختص'
                      : widget.doctor.specialization!.trim(),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    color: NabadColors.mutedText,
                  ),
                ),
                // ⚠️ التقييم مش راجع من endpoint الطبيب نفسه لسه، فمخفي مؤقتاً
                // لحد ما يتضاف بالباك بدل ما نعرض رقم وهمي.
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
    final imagePath = widget.doctor.profileImage;
    if (imagePath == null || imagePath.isEmpty) {
      return _doctorImageFallback();
    }

    return Image.network(
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
                    '${_monthName(_selectedDate.month)} ${_selectedDate.year}',
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
              onTap: () => setState(() {
                _selectedDayIndex = i;
                _syncTimeSelection();
              }),
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
                      _days[i]['name'] as String,
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
                      _days[i]['num'] as String,
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
            final time = slot['time'] as String;
            final label = slot['label'] as String;
            final isPast = _isTimeInPast(_selectedDate, time);
            final isSelected = _selectedTime == time && !isPast;

            return GestureDetector(
              onTap: isPast
                  ? null
                  : () => setState(() => _selectedTime = time),
              child: Opacity(
                opacity: isPast ? 0.4 : 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? NabadColors.softTeal
                        : NabadColors.white,
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
                          color: isPast
                              ? NabadColors.mutedText
                              : isSelected
                              ? NabadColors.primary
                              : NabadColors.darkText,
                          decoration: isPast
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      Text(
                        isPast ? 'فات الوقت' : label,
                        style: const TextStyle(
                          fontSize: 10,
                          color: NabadColors.mutedText,
                        ),
                      ),
                    ],
                  ),
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
      onTap: () => setState(() {
        _isMorning = isMorning;
        final availableTimes = _currentSlots
            .map((s) => s['time'] as String)
            .where((t) => !_isTimeInPast(_selectedDate, t))
            .toList();
        if (availableTimes.isNotEmpty &&
            !availableTimes.contains(_selectedTime)) {
          _selectedTime = availableTimes.first;
        }
      }),
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
    final monthLabel = _monthName(_selectedDate.month);
    final dayLabel =
        '$_selectedDayName $_selectedDayNum $monthLabel، $_selectedTime $period';

    return BlocBuilder<WalletCubit, WalletState>(
      builder: (context, walletState) {
        final walletBalance = walletState is WalletSuccess
            ? walletState.wallet.balance
            : null;
        final insufficientBalance =
            walletBalance != null && walletBalance < _finalPrice;

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
                      if (_pointsToRedeem > 0) ...[
                        Text(
                          '${_consultationFee.toStringAsFixed(0)} ر.س',
                          style: const TextStyle(
                            fontSize: 12,
                            color: NabadColors.mutedText,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Text(
                          '${_finalPrice.toStringAsFixed(0)} ر.س',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: NabadColors.darkText,
                          ),
                        ),
                      ] else
                        Text(
                          '${_consultationFee.toStringAsFixed(0)} ر.س',
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

              // ⚠️ رصيد المحفظة — الباك بيرفض الحجز لو الرصيد مش كافي، فبنعرضه
              // مقدّمًا هنا عشان المستخدم يعرف قبل ما يحاول يأكد.
              if (walletBalance != null) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'رصيد محفظتك: ${walletBalance.toStringAsFixed(0)} ر.س',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: insufficientBalance
                            ? Colors.red.shade700
                            : NabadColors.mutedText,
                      ),
                    ),
                    if (insufficientBalance)
                      Text(
                        'الرصيد غير كافٍ لإتمام الحجز',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.red.shade700,
                        ),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 14),

              // زر التأكيد
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      (_isBooking ||
                          _isSelectedTimeInPast ||
                          insufficientBalance)
                      ? null
                      : () => _confirmBooking(),
                  icon: _isBooking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: NabadColors.white,
                          ),
                        )
                      : const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text(
                    _isBooking
                        ? 'جاري الحجز...'
                        : _isSelectedTimeInPast
                        ? 'اختر وقتاً لم يفت بعد'
                        : insufficientBalance
                        ? 'رصيد المحفظة غير كافٍ'
                        : 'تأكيد الحجز',
                  ),
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
      },
    );
  }

  Future<void> _confirmBooking() async {
    if (_isSelectedTimeInPast || _hasInsufficientBalance) return;
    setState(() => _isBooking = true);
    try {
      await context.read<AppointmentCubit>().bookAppointment(
        doctorId: widget.doctor.id,
        date: _selectedDate,
        time: _selectedTime,
        pointsToRedeem: _pointsToRedeem,
      );
      if (!mounted) return;
      if (_pointsToRedeem > 0) {
        context.read<PointsCubit>().getPointsSummary();
      }
      _showSuccessDialog();
    } on ServerExceptions catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.errModel.errorMessage),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تعذر إتمام الحجز، حاول مرة أخرى'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  void _showSuccessDialog() {
    final period = _isMorning ? 'صباحاً' : 'مساءً';
    final monthLabel = _monthName(_selectedDate.month);
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
                'موعدك مع د. ${widget.doctor.fullName}\n$_selectedDayNum $monthLabel الساعة $_selectedTime $period',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: NabadColors.mutedText,
                  height: 1.5,
                ),
              ),
              if (_pointsToRedeem > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'تم استخدام $_pointsToRedeem نقطة (خصم ${_discountAmount.toStringAsFixed(0)} ر.س)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // يقفل الـ dialog
                  Navigator.pop(context); // يرجع لصفحة الطبيب/القائمة
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