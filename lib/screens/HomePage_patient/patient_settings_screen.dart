import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/cubits/theme_cubit.dart';
import 'package:nabad/Cubits/cubits/language_cubit.dart';
import 'package:nabad/core/localization/app_localizations.dart';
import 'package:nabad/core/theme/nabad_colors.dart';

class PatientSettingsScreen extends StatelessWidget {
  const PatientSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: context.l10n.isArabic
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(context.tr('الإعدادات')), centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              context.tr('المظهر'),
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, mode) {
                final dark = mode == ThemeMode.dark;
                return Material(
                  color: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    secondary: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: NabadColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        dark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: NabadColors.primary,
                      ),
                    ),
                    title: Text(
                      context.tr('الوضع الداكن'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      context.tr(
                        dark ? 'المظهر الداكن مفعّل' : 'المظهر الفاتح مفعّل',
                      ),
                    ),
                    value: dark,
                    activeThumbColor: NabadColors.primary,
                    onChanged: context.read<ThemeCubit>().setDarkMode,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('اللغة'),
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            BlocBuilder<LanguageCubit, Locale>(
              builder: (context, locale) {
                final isArabic = locale.languageCode == 'ar';
                return Material(
                  color: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: NabadColors.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.translate_rounded,
                            color: NabadColors.primary,
                          ),
                        ),
                        title: Text(
                          context.tr('لغة التطبيق'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          context.tr(isArabic ? 'العربية' : 'الإنجليزية'),
                        ),
                        onTap: context.read<LanguageCubit>().toggleLanguage,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: context
                                .read<LanguageCubit>()
                                .toggleLanguage,
                            icon: const Icon(Icons.swap_horiz_rounded),
                            label: Text(
                              context.tr(
                                isArabic
                                    ? 'تبديل إلى الإنجليزية'
                                    : 'التبديل إلى العربية',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
