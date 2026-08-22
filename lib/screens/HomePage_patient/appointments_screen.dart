import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/cubits/appointment_cubit.dart';
import '../../Cubits/states/appointment_state.dart';
import '../../Models/appointment_model.dart';
import '../../core/Error/exceptions.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/nabd_colors.dart';
import '../../core/time/clinic_clock.dart';
import '../../widgets/doctors/appointment_card.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentCubit>().getAppointments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ⚠️ عمداً مفيش _cancelAppointment هنا. حسب توثيق الباك: "المريض لا يملك
  // route إلغاء مباشر" — الإلغاء بس من العيادة (secretary). لو حبينا نوجّه
  // المريض، بنعرضله رسالة "تواصل مع العيادة" بدل زر إلغاء فعلي.

  Future<void> _rescheduleAppointment(
    AppointmentModel appointment, {
    bool refreshedAfterConflict = false,
  }) async {
    final now = ClinicClock.today();
    try {
      final dates = await context
          .read<AppointmentCubit>()
          .getDoctorAvailableDates(
            doctorId: appointment.doctor.id,
            from: now,
            to: now.add(const Duration(days: 30)),
            ignoreAppointmentId: appointment.id,
          );
      if (!mounted) return;
      final availableKeys = dates
          .where((item) => item.isAvailable)
          .map((item) => _dateKey(item.date))
          .toSet();
      if (availableKeys.isEmpty) {
        _showMessage(context.tr('لا توجد أيام متاحة لإعادة الجدولة حالياً.'));
        return;
      }
      final firstAvailable = dates.firstWhere((item) => item.isAvailable).date;
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: firstAvailable,
        firstDate: DateTime(now.year, now.month, now.day),
        lastDate: now.add(const Duration(days: 30)),
        selectableDayPredicate: (date) =>
            availableKeys.contains(_dateKey(date)),
        helpText: context.tr('اختر تاريخ الموعد الجديد'),
        cancelText: context.tr('إلغاء'),
        confirmText: context.tr('التالي'),
        builder: (context, child) => Directionality(
          textDirection: context.l10n.isArabic
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child!,
        ),
      );
      if (pickedDate == null || !mounted) return;

      final availability = await context
          .read<AppointmentCubit>()
          .getDoctorAvailability(
            doctorId: appointment.doctor.id,
            date: pickedDate,
            ignoreAppointmentId: appointment.id,
          );
      if (!mounted) return;
      final slots = availability.slots.where((slot) => slot.available).toList();
      if (slots.isEmpty) {
        _showMessage(context.tr('لم يعد هناك وقت متاح في هذا اليوم.'));
        return;
      }
      final pickedTime = await showDialog<String>(
        context: context,
        builder: (dialogContext) => Directionality(
          textDirection: context.l10n.isArabic
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: SimpleDialog(
            title: Text(context.tr('اختر الوقت الجديد')),
            children: slots
                .map(
                  (slot) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(dialogContext, slot.time),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '${slot.time} - ${slot.endTime}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      );
      if (pickedTime == null || !mounted) return;

      await context.read<AppointmentCubit>().rescheduleAppointment(
        id: appointment.id,
        date: pickedDate,
        time: pickedTime,
      );
      if (!mounted) return;
      await context.read<AppointmentCubit>().getDoctorAvailability(
        doctorId: appointment.doctor.id,
        date: pickedDate,
        ignoreAppointmentId: appointment.id,
      );
      if (!mounted) return;
      _showMessage(context.tr('تم تحديث موعدك بنجاح.'));
    } on ServerExceptions catch (e) {
      if (!mounted) return;
      _showMessage(e.errModel.errorMessage, error: true);
      if (e.statusCode == 422 && !refreshedAfterConflict) {
        _showMessage(
          context.tr('تم تحديث الأوقات، اختر وقتاً جديداً.'),
          error: true,
        );
        await _rescheduleAppointment(appointment, refreshedAfterConflict: true);
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        context.tr('تعذر تعديل الموعد، حاول مرة أخرى.'),
        error: true,
      );
    }
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr(message)),
        backgroundColor: error ? Colors.red.shade700 : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Kept temporarily as a fallback while the availability flow is rolled out.
  // ignore: unused_element
  Future<void> _legacyRescheduleAppointment(
    AppointmentModel appointment,
  ) async {
    final now = ClinicClock.today();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      helpText: context.tr('اختر تاريخ الموعد الجديد'),
      cancelText: context.tr('إلغاء'),
      confirmText: context.tr('التالي'),
      builder: (context, child) => Directionality(
        textDirection: context.l10n.isArabic
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: child!,
      ),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      helpText: context.tr('اختر وقت الموعد الجديد'),
      cancelText: context.tr('إلغاء'),
      confirmText: context.tr('تأكيد'),
      builder: (context, child) => Directionality(
        textDirection: context.l10n.isArabic
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: child!,
      ),
    );
    if (pickedTime == null || !mounted) return;

    final formattedTime =
        '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';

    try {
      await context.read<AppointmentCubit>().rescheduleAppointment(
        id: appointment.id,
        date: pickedDate,
        time: formattedTime,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('تم تحديث موعدك بنجاح'))),
      );
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
          content: Text(context.tr('تعذر تعديل الموعد، حاول مرة أخرى.')),
        ),
      );
    }
  }

  Future<void> _rateAppointment(AppointmentModel appointment) async {
    int rating = 8; // قيمة افتراضية معقولة بمنتصف المقياس
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: context.l10n.isArabic
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              context.tr('قيّم تجربتك'),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: NabadColors.darkText,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('كيف كانت تجربتك مع {name}؟', {
                    'name': appointment.doctorName,
                  }),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: NabadColors.mutedText,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$rating / 10',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFF5A623),
                  ),
                ),
                Slider(
                  value: rating.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: const Color(0xFFF5A623),
                  label: '$rating',
                  onChanged: (value) {
                    setDialogState(() => rating = value.round());
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  context.tr('إلغاء'),
                  style: const TextStyle(color: NabadColors.mutedText),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NabadColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: Text(
                  context.tr('إرسال التقييم'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<AppointmentCubit>().rateAppointment(
        appointment.id,
        rating,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('شكراً لتقييمك!'))));
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
          content: Text(context.tr('تعذر إرسال التقييم، حاول مرة أخرى')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: context.l10n.isArabic
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: NabadColors.background,
        appBar: AppBar(
          title: Text(context.tr('مواعيدي')),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            labelColor: NabadColors.primary,
            unselectedLabelColor: NabadColors.mutedText,
            indicatorColor: NabadColors.primary,
            tabs: [
              Tab(text: context.tr('قيد الانتظار')),
              Tab(text: context.tr('المنتهية')),
              Tab(text: context.tr('الملغاة')),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          backgroundColor: NabadColors.primary,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            buildList('confirmed'),
            buildList('completed'),
            buildList('canceled'),
          ],
        ),
      ),
    );
  }

  Widget buildList(String status) {
    return BlocBuilder<AppointmentCubit, AppointmentState>(
      builder: (context, state) {
        if (state is AppointmentLoading) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (state is AppointmentError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr(state.message),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: NabadColors.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () =>
                        context.read<AppointmentCubit>().getAppointments(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(context.tr('إعادة المحاولة')),
                    style: TextButton.styleFrom(
                      foregroundColor: NabadColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is! AppointmentSuccess) {
          return const SizedBox.shrink();
        }

        final filtered = state.appointments
            .where((a) => _matchesStatus(a, status))
            .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 64,
                  color: NabadColors.primary.withOpacity(0.25),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr('لا توجد مواعيد'),
                  style: const TextStyle(
                    color: NabadColors.mutedText,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => context.read<AppointmentCubit>().getAppointments(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) => AppointmentCard(
              appointment: filtered[index],
              onReschedule: () => _rescheduleAppointment(filtered[index]),
              onRate: () => _rateAppointment(filtered[index]),
            ),
          ),
        );
      },
    );
  }

  /// التصنيف حسب توثيق الباك: 4 حالات فعلية (confirmed, cancelled,
  /// completed, no_show) بدل 3 تابات، فبنجمع no_show مع الملغاة (الاتنين
  /// معناهم "الموعد ما اتنفذش")، ونضيف "بانتظار تأكيد العيادة" (confirmed
  /// بس عدّى وقتها) لتاب المنتهية عشان ما تفضلش عالقة بقيد الانتظار.
  bool _matchesStatus(AppointmentModel appointment, String tabStatus) {
    if (appointment.isCanceled ||
        appointment.isNoShow ||
        appointment.isRejected) {
      return tabStatus == 'canceled';
    }

    final isConfirmedActive = appointment.status == 'confirmed';

    if (tabStatus == 'confirmed') {
      return appointment.isPendingApproval ||
          (isConfirmedActive && !appointment.isPastScheduledTime);
    }

    if (tabStatus == 'completed') {
      return appointment.isCompleted ||
          (isConfirmedActive && appointment.isPastScheduledTime);
    }

    return false;
  }
}
