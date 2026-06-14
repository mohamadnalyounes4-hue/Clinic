import 'package:flutter/material.dart';
import '../../Models/appointment_model.dart';
import '../../core/theme/nabd_colors.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onCancel; // ✅ جديد
  final VoidCallback onReschedule; // ✅ جديد

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.onCancel,
    required this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = appointment.status == 'pending';
    final isCanceled = appointment.status == 'canceled';

    return Card(
      color: NabadColors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: NabadColors.divider, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ✅ صورة الطبيب + الاسم + التخصص
            Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    appointment.imagePath,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: NabadColors.softTeal,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: NabadColors.primary,
                        size: 34,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        appointment.doctorName,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: NabadColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: NabadColors.softTeal,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          appointment.specialty,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: NabadColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(color: NabadColors.divider, height: 1),
            const SizedBox(height: 12),

            // التاريخ والوقت
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      appointment.time,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: NabadColors.darkText,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: NabadColors.mutedText,
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      appointment.date,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: NabadColors.darkText,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 15,
                      color: NabadColors.mutedText,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Divider(color: NabadColors.divider, height: 1),

            // ✅ أزرار للمعلق / شارة للملغى أو المكتمل
            if (isPending)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    child: const Text(
                      'إلغاء الموعد',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE53935),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onReschedule,
                    child: const Text(
                      'إعادة جدولة',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: NabadColors.darkText,
                      ),
                    ),
                  ),
                ],
              ),

            if (!isPending)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isCanceled
                          ? const Color(0xFFFFEBEE)
                          : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      isCanceled ? 'ملغى' : 'مكتمل',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isCanceled
                            ? const Color(0xFFE53935)
                            : const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
