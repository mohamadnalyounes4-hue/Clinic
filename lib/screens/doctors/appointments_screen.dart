import 'package:flutter/material.dart';
import '../../Models/appointment_model.dart';
import '../../core/theme/nabd_colors.dart';
import '../../widgets/doctors/appointment_card.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ✅ أضفنا imagePath لكل طبيب
  final List<Appointment> appointments = [
    Appointment(
      doctorName: 'د. سمير المنصور',
      specialty: 'أخصائي جراحة القلب',
      date: '15 أكتوبر، 2023',
      time: '10:30 صباحاً',
      imagePath: 'assets/images/Male.jpg',
      status: 'pending',
    ),
    Appointment(
      doctorName: 'د. ليلى حسن',
      specialty: 'أخصائية طب الأطفال',
      date: '22 أكتوبر، 2023',
      time: '01:45 مساءً',
      imagePath: 'assets/images/Female.jpg',
      status: 'pending',
    ),
  ];

  @override
  void initState() {
    _tabController = TabController(length: 3, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ✅ دالة الإلغاء مع Dialog تأكيد
  void _cancelAppointment(Appointment appointment) {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'إلغاء الموعد',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: NabadColors.darkText,
            ),
          ),
          content: Text(
            'هل أنت متأكد من إلغاء موعدك مع ${appointment.doctorName}؟',
            style: const TextStyle(color: NabadColors.mutedText, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'تراجع',
                style: TextStyle(color: NabadColors.mutedText),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => appointment.status = 'canceled');
                Navigator.pop(context);
                _tabController.animateTo(2); // ✅ ينتقل لتبويب الملغاة
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: const Text(
                'تأكيد الإلغاء',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: NabadColors.background,
        appBar: AppBar(
          title: const Text('مواعيدي'),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            labelColor: NabadColors.primary,
            unselectedLabelColor: NabadColors.mutedText,
            indicatorColor: NabadColors.primary,
            tabs: const [
              Tab(text: 'قيد الانتظار'),
              Tab(text: 'المنتهية'),
              Tab(text: 'الملغاة'),
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
            buildList('pending'),
            buildList('completed'),
            buildList('canceled'),
          ],
        ),
      ),
    );
  }

  Widget buildList(String status) {
    final filtered = appointments.where((a) => a.status == status).toList();

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
            const Text(
              'لا توجد مواعيد',
              style: TextStyle(
                color: NabadColors.mutedText,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) => AppointmentCard(
        appointment: filtered[index],
        onCancel: () => _cancelAppointment(filtered[index]), // ✅
        onReschedule: () {},
      ),
    );
  }
}
