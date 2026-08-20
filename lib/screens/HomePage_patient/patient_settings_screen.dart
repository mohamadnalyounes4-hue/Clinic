import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/cubits/theme_cubit.dart';
import 'package:nabad/core/theme/nabad_colors.dart';

class PatientSettingsScreen extends StatelessWidget {
  const PatientSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الإعدادات'), centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              'المظهر',
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
                return Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
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
                    title: const Text(
                      'الوضع الداكن',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      dark ? 'المظهر الداكن مفعّل' : 'المظهر الفاتح مفعّل',
                    ),
                    value: dark,
                    activeThumbColor: NabadColors.primary,
                    onChanged: context.read<ThemeCubit>().setDarkMode,
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
