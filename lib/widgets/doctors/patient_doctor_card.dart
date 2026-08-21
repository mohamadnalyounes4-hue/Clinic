import 'package:flutter/material.dart';
import 'package:nabad/Models/doctor_model.dart';
import 'package:nabad/core/theme/nabd_colors.dart';
import 'package:nabad/core/localization/app_localizations.dart';

class PatientDoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onTap;

  const PatientDoctorCard({
    super.key,
    required this.doctor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
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
                child: doctor.profileImage != null
                    ? Image.network(
                        doctor.profileImage!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _AvatarFallback(
                          initials: _initials(doctor.fullName),
                        ),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return const _AvatarFallback();
                        },
                      )
                    : _AvatarFallback(initials: _initials(doctor.fullName)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.isArabic
                          ? 'د. ${doctor.fullName}'
                          : 'Dr. ${doctor.fullName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      context.tr(doctor.specialization ?? ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: NabadColors.mutedText,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (doctor.yearsOfExperience != null) ...[
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.workspace_premium_rounded,
                            color: Color(0xFFE2A228),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.isArabic
                                ? '${doctor.yearsOfExperience} ${context.tr('سنوات خبرة')}'
                                : '${doctor.yearsOfExperience} ${context.tr('سنوات خبرة')}',
                            style: const TextStyle(
                              color: Color(0xFFE2A228),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NabadColors.primary.withAlpha(35)),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 17,
                  color: NabadColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ');
    return parts.take(2).map((word) => word.isEmpty ? '' : word[0]).join();
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initials;

  const _AvatarFallback({this.initials = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      color: const Color(0xFFC9F3F8),
      alignment: Alignment.center,
      child: initials.isEmpty
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              initials,
              style: const TextStyle(
                color: NabadColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}
