import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/cubits/appointment_cubit.dart';
import 'package:nabad/Cubits/cubits/points_cubit.dart';
import 'package:nabad/Cubits/cubits/wallet_cubit.dart';
import '../../Cubits/states/points_state.dart';
import '../../Cubits/states/wallet_state.dart';
import '../../Models/doctor_model.dart';
import '../../Models/doctor_availability_model.dart';
import '../../Models/points_model.dart';
import '../../core/Error/exceptions.dart';
import '../../core/localization/app_localizations.dart';
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
  String _selectedTime = '';
  bool _isMorning = true;
  bool _isBooking = false;
  bool _isScheduleLoading = true;
  String? _scheduleError;
  List<DoctorAvailabilitySlotModel> _availabilitySlots = const [];

  // ── النقاط المستخدمة كخصم ──
  int _pointsToRedeem = 0;
  PointsRedemptionPreviewModel? _serverPreview;
  bool _isPreviewLoading = false;
  String? _previewError;

  @override
  void initState() {
    super.initState();
    context.read<PointsCubit>().getPointsSummary();
    context.read<WalletCubit>().loadWallet();
    _loadDoctorSchedule();
  }

  Future<void> _loadDoctorSchedule() async {
    try {
      final dates = await context
          .read<AppointmentCubit>()
          .getDoctorAvailableDates(
            doctorId: widget.doctor.id,
            from: _days.first['date'] as DateTime,
            to: _days.last['date'] as DateTime,
          );
      final byDate = {for (final item in dates) _dateKey(item.date): item};
      for (final day in _days) {
        final availability = byDate[_dateKey(day['date'] as DateTime)];
        day['isAvailable'] = availability?.isAvailable ?? false;
        day['availableSlots'] = availability?.availableSlots ?? 0;
      }
      final firstAvailable = _days.indexWhere(
        (day) => day['isAvailable'] == true,
      );
      String? bookingBlockReason;
      for (final item in dates) {
        if (item.bookingBlockReason != null) {
          bookingBlockReason = item.bookingBlockReason;
          break;
        }
      }
      if (!mounted) return;
      setState(() {
        _selectedDayIndex = firstAvailable < 0 ? 0 : firstAvailable;
        _scheduleError = _bookingBlockMessage(bookingBlockReason);
      });
      await _loadAvailabilityForSelectedDate();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _availabilitySlots = const [];
        _scheduleError = 'تعذر جلب فترات دوام الطبيب';
        _isScheduleLoading = false;
        _selectedTime = '';
      });
    }
  }

  Future<void> _loadAvailabilityForSelectedDate() async {
    setState(() {
      _isScheduleLoading = true;
      _selectedTime = '';
      _scheduleError = null;
    });
    try {
      final availability = await context
          .read<AppointmentCubit>()
          .getDoctorAvailability(
            doctorId: widget.doctor.id,
            date: _selectedDate,
          );
      if (!mounted) return;
      setState(() {
        _availabilitySlots = availability.slots
            .where((slot) => slot.available)
            .toList();
        _isScheduleLoading = false;
        _scheduleError = _bookingBlockMessage(availability.bookingBlockReason);
        _syncTimeSelection();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _availabilitySlots = const [];
        _isScheduleLoading = false;
        _scheduleError = 'تعذر جلب الأوقات المتاحة لهذا اليوم';
      });
    }
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String? _bookingBlockMessage(String? reason) {
    if (reason == 'same_specialty') {
      return 'لديك موعد قادم في نفس الاختصاص. يمكنك الحجز بعد انتهاء الموعد الحالي أو إلغائه.';
    }

    return null;
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

  bool get _hasSelectedTime => _selectedTime.isNotEmpty;

  bool get _isSelectedTimeInPast =>
      _hasSelectedTime && _isTimeInPast(_selectedDate, _selectedTime);

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
    _selectedTime = availableTimes.contains(_selectedTime)
        ? _selectedTime
        : availableTimes.isEmpty
        ? ''
        : availableTimes.first;
  }

  // ── بيانات الأيام ──
  // بنعرض أقرب 6 أيام حقيقية من تاريخ اليوم. اختيار الوقت حر بالكامل
  // (مفيش ربط بدوام الطبيب حاليًا)، والباك هو اللي يرفض أي تعارض فعلي
  // وقت تأكيد الحجز.
  late final List<Map<String, dynamic>> _days = List.generate(14, (i) {
    final date = DateTime.now().add(Duration(days: i));
    return {
      'name': _weekdayName(date.weekday),
      'num': date.day.toString().padLeft(2, '0'),
      'date': date,
      'isAvailable': false,
      'availableSlots': 0,
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
      1: 'يناير',
      2: 'فبراير',
      3: 'مارس',
      4: 'أبريل',
      5: 'مايو',
      6: 'يونيو',
      7: 'يوليو',
      8: 'أغسطس',
      9: 'سبتمبر',
      10: 'أكتوبر',
      11: 'نوفمبر',
      12: 'ديسمبر',
    };
    return names[month] ?? '';
  }

  int? _timeToMinutes(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }

  List<Map<String, dynamic>> get _daySlots {
    return _availabilitySlots
        .map(
          (slot) => <String, dynamic>{
            'time': slot.time,
            'label': (_timeToMinutes(slot.time) ?? 0) < 12 * 60
                ? 'صباحاً'
                : 'مساءً',
          },
        )
        .toList();
  }

  List<Map<String, dynamic>> get _morningSlots => _daySlots
      .where((slot) => (_timeToMinutes(slot['time'] as String) ?? 0) < 12 * 60)
      .toList();

  List<Map<String, dynamic>> get _eveningSlots => _daySlots
      .where((slot) => (_timeToMinutes(slot['time'] as String) ?? 0) >= 12 * 60)
      .toList();

  List<Map<String, dynamic>> get _currentSlots =>
      _isMorning ? _morningSlots : _eveningSlots;

  String get _selectedDayName => _days[_selectedDayIndex]['name'] as String;
  String get _selectedDayNum => _days[_selectedDayIndex]['num'] as String;
  DateTime get _selectedDate => _days[_selectedDayIndex]['date'] as DateTime;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: context.l10n.isArabic
          ? TextDirection.rtl
          : TextDirection.ltr,
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

  double get _discountPercent => _pointsToRedeem == 0
      ? 0
      : (_serverPreview?.discountPercentage ??
            LoyaltyPolicy.discountPercentage);

  double get _discountAmount => _pointsToRedeem == 0
      ? 0
      : (_serverPreview?.discountAmount ??
            LoyaltyPolicy.discountAmount(_consultationFee));

  double get _finalPrice => _pointsToRedeem == 0
      ? _consultationFee
      : (_serverPreview?.finalPrice ??
            LoyaltyPolicy.finalPrice(_consultationFee));

  bool get _isPreviewValid =>
      _pointsToRedeem == 0 ||
      (!_isPreviewLoading &&
          _previewError == null &&
          _serverPreview?.matchesLoyaltyPolicy(
                consultationFee: _consultationFee,
              ) ==
              true);

  void _changePoints(int value) {
    setState(() {
      _pointsToRedeem = value;
      _serverPreview = null;
      _previewError = null;
      _isPreviewLoading = value > 0;
    });
    if (value <= 0) return;
    _loadPointsPreview(value);
  }

  Future<void> _loadPointsPreview(int requestedPoints) async {
    if (!mounted || requestedPoints != _pointsToRedeem) return;
    setState(() {
      _isPreviewLoading = true;
      _previewError = null;
      _serverPreview = null;
    });
    try {
      final preview = await context.read<PointsCubit>().previewRedemption(
        doctorId: widget.doctor.id,
        pointsToRedeem: requestedPoints,
      );
      if (!mounted || requestedPoints != _pointsToRedeem) return;
      if (!preview.matchesLoyaltyPolicy(consultationFee: _consultationFee)) {
        setState(() {
          _serverPreview = null;
          _isPreviewLoading = false;
          _previewError =
              'إعدادات الخصم على الخادم لا تطابق 40 نقطة مقابل خصم 30%';
        });
        return;
      }
      setState(() {
        _serverPreview = preview;
        _isPreviewLoading = false;
        _previewError = null;
      });
    } on ServerExceptions catch (error) {
      if (!mounted || requestedPoints != _pointsToRedeem) return;
      setState(() {
        _serverPreview = null;
        _isPreviewLoading = false;
        _previewError = error.errModel.errorMessage;
      });
    } catch (_) {
      if (!mounted || requestedPoints != _pointsToRedeem) return;
      setState(() {
        _serverPreview = null;
        _isPreviewLoading = false;
        _previewError = 'تعذر التحقق من قيمة الخصم';
      });
    }
  }

  double? get _walletBalance {
    final state = context.read<WalletCubit>().state;
    return state is WalletSuccess ? state.wallet.balance : null;
  }

  bool get _hasInsufficientBalance =>
      _walletBalance != null && _walletBalance! < _finalPrice;

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
        if (!LoyaltyPolicy.canRedeem(summary.pointsBalance)) {
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
              Text(
                context.tr('اختر طريقة الحجز'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: NabadColors.darkText,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                context.tr(
                  'رصيدك {balance} نقطة — كل موعد تحجزه يمنحك 20 نقطة بعد اكتماله',
                  {'balance': summary.pointsBalance},
                ),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 11,
                  color: NabadColors.mutedText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildBookingPriceOption(
                selected: _pointsToRedeem == 0,
                title: context.tr('حجز عادي بالسعر الكامل'),
                subtitle: context.tr('احتفظ بنقاطك لاستخدامها لاحقاً'),
                price: _consultationFee,
                onTap: () => _changePoints(0),
              ),
              const SizedBox(height: 10),
              _buildBookingPriceOption(
                selected:
                    _pointsToRedeem == LoyaltyPolicy.pointsRequiredForDiscount,
                title: context.tr('استخدام 40 نقطة'),
                subtitle: context.tr('خصم 30% على هذا الحجز'),
                price: LoyaltyPolicy.finalPrice(_consultationFee),
                originalPrice: _consultationFee,
                onTap: () =>
                    _changePoints(LoyaltyPolicy.pointsRequiredForDiscount),
              ),
              if (_pointsToRedeem > 0) ...[
                const SizedBox(height: 10),
                const Divider(color: NabadColors.divider, height: 1),
                const SizedBox(height: 10),
                if (_isPreviewLoading)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text(
                        context.tr('جاري التحقق من الخصم...'),
                        style: const TextStyle(
                          color: NabadColors.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                else if (_previewError != null)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr(_previewError!),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: context.tr('إعادة المحاولة'),
                        onPressed: () => _loadPointsPreview(_pointsToRedeem),
                        icon: const Icon(Icons.refresh_rounded),
                        color: NabadColors.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '- ${_discountAmount.toStringAsFixed(0)} ${context.tr('ر.س')}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.green.shade700,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: Colors.green.shade700,
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${context.tr('خصم')} ${_discountPercent.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
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

  Widget _buildBookingPriceOption({
    required bool selected,
    required String title,
    required String subtitle,
    required double price,
    required VoidCallback onTap,
    double? originalPrice,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected
              ? NabadColors.primary.withAlpha(14)
              : NabadColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? NabadColors.primary : NabadColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? NabadColors.primary : NabadColors.mutedText,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: NabadColors.darkText,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: NabadColors.mutedText,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (originalPrice != null)
                  Text(
                    '${originalPrice.toStringAsFixed(0)} ${context.tr('ر.س')}',
                    style: const TextStyle(
                      color: NabadColors.mutedText,
                      fontSize: 10.5,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                Text(
                  '${price.toStringAsFixed(0)} ${context.tr('ر.س')}',
                  style: TextStyle(
                    color: selected
                        ? NabadColors.primary
                        : NabadColors.darkText,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
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
            Image.asset(
              'assets/images/logo.png',
              width: 72,
              height: 38,
              fit: BoxFit.contain,
              semanticLabel: 'Nabd',
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
        textDirection: context.l10n.isArabic
            ? TextDirection.rtl
            : TextDirection.ltr,
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
                  '${context.l10n.isArabic ? 'د.' : 'Dr.'} ${widget.doctor.fullName}'
                      .trim(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: NabadColors.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (widget.doctor.specialization ?? '').trim().isEmpty
                      ? context.tr('طبيب مختص')
                      : context.tr(widget.doctor.specialization!.trim()),
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
                    child: Text(
                      context.tr('متاح'),
                      style: const TextStyle(
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
                    '${context.tr(_monthName(_selectedDate.month))} ${_selectedDate.year}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: NabadColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              context.tr('اختر التاريخ'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: NabadColors.darkText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // أيام الأسبوع
        LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _days.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  // عكس الترتيب لـ RTL
                  final i = _days.length - 1 - index;
                  final isSelected = _selectedDayIndex == i;
                  final isAvailable = _days[i]['isAvailable'] == true;
                  return GestureDetector(
                    onTap: !isAvailable || _isScheduleLoading
                        ? null
                        : () {
                            setState(() => _selectedDayIndex = i);
                            _loadAvailabilityForSelectedDate();
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 58,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected && isAvailable
                            ? NabadColors.primary
                            : NabadColors.white,
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
                            context.tr(_days[i]['name'] as String),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected && isAvailable
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
                              color: isSelected && isAvailable
                                  ? NabadColors.white
                                  : NabadColors.darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
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
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: NabadColors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: NabadColors.divider),
                  ),
                  child: Row(
                    children: [
                      _periodTab(context.tr('المسائية'), false),
                      _periodTab(context.tr('الصباحية'), true),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                context.tr('الفترات المتاحة'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: NabadColors.darkText,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // شبكة الأوقات الحقيقية فقط
        if (_isScheduleLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 22),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_currentSlots.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
            decoration: BoxDecoration(
              color: NabadColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NabadColors.divider),
            ),
            child: Text(
              context.tr(_scheduleError ?? 'لا توجد فترات متاحة لهذا اليوم'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: NabadColors.mutedText,
              ),
            ),
          )
        else
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
                          isPast ? context.tr('فات الوقت') : context.tr(label),
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
        _selectedTime = availableTimes.contains(_selectedTime)
            ? _selectedTime
            : availableTimes.isEmpty
            ? ''
            : availableTimes.first;
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
        textDirection: context.l10n.isArabic
            ? TextDirection.rtl
            : TextDirection.ltr,
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
              children: [
                Text(
                  context.tr('ملاحظة طبية'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: NabadColors.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr(
                    'يرجى إحضار التقارير الطبية السابقة إذا كانت متوفرة.',
                  ),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
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
    final period = context.tr(_isMorning ? 'ص' : 'م');
    final monthLabel = context.tr(_monthName(_selectedDate.month));
    final dayLabel = _hasSelectedTime
        ? '${context.tr(_selectedDayName)} $_selectedDayNum $monthLabel، $_selectedTime $period'
        : '${context.tr(_selectedDayName)} $_selectedDayNum $monthLabel — ${context.tr('لم يتم اختيار وقت')}';

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('التاريخ المختار'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: NabadColors.mutedText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          dayLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: NabadColors.darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // السعر
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        context.tr('قيمة الكشف'),
                        style: const TextStyle(
                          fontSize: 11,
                          color: NabadColors.mutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_pointsToRedeem > 0) ...[
                        Text(
                          '${_consultationFee.toStringAsFixed(0)} ${context.tr('ر.س')}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: NabadColors.mutedText,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Text(
                          '${_finalPrice.toStringAsFixed(0)} ${context.tr('ر.س')}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: NabadColors.darkText,
                          ),
                        ),
                      ] else
                        Text(
                          '${_consultationFee.toStringAsFixed(0)} ${context.tr('ر.س')}',
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
                      context.tr('رصيد محفظتك: {balance} {currency}', {
                        'balance': walletBalance.toStringAsFixed(0),
                        'currency': context.tr('ر.س'),
                      }),
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
                        context.tr('الرصيد غير كافٍ لإتمام الحجز'),
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
                          !_hasSelectedTime ||
                          _isSelectedTimeInPast ||
                          insufficientBalance ||
                          !_isPreviewValid)
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
                    context.tr(
                      _isBooking
                          ? 'جاري الحجز...'
                          : _isPreviewLoading
                          ? 'جاري التحقق من الخصم...'
                          : _previewError != null
                          ? 'تحقق من خصم النقاط'
                          : !_hasSelectedTime
                          ? 'لا توجد فترات متاحة'
                          : _isSelectedTimeInPast
                          ? 'اختر وقتاً لم يفت بعد'
                          : insufficientBalance
                          ? 'رصيد المحفظة غير كافٍ'
                          : 'تأكيد الحجز',
                    ),
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
    if (!_hasSelectedTime ||
        _isSelectedTimeInPast ||
        _hasInsufficientBalance ||
        !_isPreviewValid) {
      return;
    }
    setState(() => _isBooking = true);
    try {
      if (_pointsToRedeem > 0) {
        final preview = await context.read<PointsCubit>().previewRedemption(
          doctorId: widget.doctor.id,
          pointsToRedeem: _pointsToRedeem,
        );
        if (!preview.matchesLoyaltyPolicy(consultationFee: _consultationFee)) {
          if (!mounted) return;
          setState(() {
            _serverPreview = null;
            _previewError =
                'إعدادات الخصم على الخادم لا تطابق 40 نقطة مقابل خصم 30%';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr(_previewError!)),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        if (!mounted) return;
        setState(() => _serverPreview = preview);
      }
      await context.read<AppointmentCubit>().bookAppointment(
        doctorId: widget.doctor.id,
        date: _selectedDate,
        time: _selectedTime,
        pointsToRedeem: _pointsToRedeem,
      );
      if (!mounted) return;
      _showSuccessDialog();
    } on ServerExceptions catch (e) {
      if (!mounted) return;
      _loadAvailabilityForSelectedDate();
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
          content: Text(context.tr('تعذر إتمام الحجز، حاول مرة أخرى')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  void _showSuccessDialog() {
    final period = context.tr(_isMorning ? 'صباحاً' : 'مساءً');
    final monthLabel = context.tr(_monthName(_selectedDate.month));
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: context.l10n.isArabic
            ? TextDirection.rtl
            : TextDirection.ltr,
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
              Text(
                context.tr('تم إرسال طلب الحجز'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: NabadColors.darkText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(
                  'طلبك مع {doctor}\n{date} الساعة {time} {period}\nبانتظار موافقة السكرتاريا',
                  {
                    'doctor':
                        '${context.l10n.isArabic ? 'د.' : 'Dr.'} ${widget.doctor.fullName}',
                    'date': '$_selectedDayNum $monthLabel',
                    'time': _selectedTime,
                    'period': period,
                  },
                ),
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
                  context.tr(
                    'سيتم استخدام {points} نقطة بعد الموافقة (خصم {amount} {currency})',
                    {
                      'points': _pointsToRedeem,
                      'amount': _discountAmount.toStringAsFixed(0),
                      'currency': context.tr('ر.س'),
                    },
                  ),
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
                child: Text(
                  context.tr('حسناً'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
