import 'package:flutter/material.dart';
import '../../Models/appointment_model.dart';
import '../../core/theme/nabd_colors.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onReschedule;
  final VoidCallback onRate; // تقييم الطبيب بعد اكتمال الموعد

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.onReschedule,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    // حسب توثيق الباك، حالات الموعد الفعلية: confirmed, cancelled,
    // completed, no_show. مفيش "pending".
    final isConfirmed = appointment.status == 'confirmed';
    // نشطة فعليًا: مؤكدة وميعادها ما جاش لسه (فيها إعادة جدولة بس)
    final isActive = isConfirmed && !appointment.isPastScheduledTime;
    // عدّى وقتها بس لسه مؤكدة بالباك (العيادة ما أكدتش الإكمال رسميًا بعد)
    final isPastUnconfirmed = isConfirmed && appointment.isPastScheduledTime;
    final isCanceled = appointment.isCanceled;
    final isNoShow = appointment.isNoShow;

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
                  child: _AppointmentImage(imagePath: appointment.imagePath),
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

            if (isActive)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'للإلغاء تواصل مع العيادة',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: NabadColors.mutedText.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
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

            if (!isActive)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (appointment.canRate)
                      TextButton.icon(
                        onPressed: onRate,
                        icon: const Icon(
                          Icons.star_outline_rounded,
                          size: 18,
                          color: Color(0xFFF5A623),
                        ),
                        label: const Text(
                          'قيّم الطبيب',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF5A623),
                          ),
                        ),
                      )
                    else if (appointment.rating != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: Color(0xFFF5A623),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'تقييمك: ${appointment.rating}/10',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: NabadColors.mutedText,
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox.shrink(),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isCanceled
                            ? const Color(0xFFFFEBEE)
                            : isNoShow
                            ? const Color(0xFFF0F0F0)
                            : isPastUnconfirmed
                            ? const Color(0xFFFFF3E0)
                            : const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        isCanceled
                            ? 'ملغى'
                            : isNoShow
                            ? 'لم يحضر'
                            : isPastUnconfirmed
                            ? 'بانتظار تأكيد العيادة'
                            : 'مكتمل',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isCanceled
                              ? const Color(0xFFE53935)
                              : isNoShow
                              ? const Color(0xFF757575)
                              : isPastUnconfirmed
                              ? const Color(0xFFEF6C00)
                              : const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentImage extends StatelessWidget {
  final String imagePath;

  const _AppointmentImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _AppointmentImageFallback(),
      );
    }

    if (imagePath.isNotEmpty) {
      return Image.asset(
        imagePath,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _AppointmentImageFallback(),
      );
    }

    return const _AppointmentImageFallback();
  }
}

class _AppointmentImageFallback extends StatelessWidget {
  const _AppointmentImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
