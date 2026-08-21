import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabad/Cubits/cubits/language_cubit.dart';
import 'package:nabad/Cubits/cubits/theme_cubit.dart';
import 'package:nabad/core/Cache/cache_helper.dart';
import 'package:nabad/core/localization/app_localizations.dart';
import 'package:nabad/screens/HomePage_patient/patient_settings_screen.dart';
import 'package:nabad/widgets/patient_login/patient_login_hero.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('points and doctor copy have English translations', () {
    const localizations = AppLocalizations(Locale('en'));

    expect(localizations.translate('رصيد نقاطك'), 'Your points balance');
    expect(localizations.translate('التفاصيل'), 'Details');
    expect(
      localizations.translate('باقي {left} نقطة لتحصل على خصم {discount}%', {
        'left': 40,
        'discount': 10,
      }),
      '40 points left to get a 10% discount',
    );
    expect(localizations.translate('إجراءات سريعة'), 'Quick actions');
    expect(localizations.translate('30 دقيقة'), '30 min');
  });

  testWidgets('language can be changed from settings and is persisted', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();

    final languageCubit = LanguageCubit();
    final themeCubit = ThemeCubit();
    addTearDown(languageCubit.close);
    addTearDown(themeCubit.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: languageCubit),
          BlocProvider.value(value: themeCubit),
        ],
        child: BlocBuilder<LanguageCubit, Locale>(
          builder: (context, locale) => MaterialApp(
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const PatientSettingsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('لغة التطبيق'), findsOneWidget);

    await tester.tap(find.text('تبديل إلى الإنجليزية'));
    await tester.pumpAndSettle();

    expect(languageCubit.state.languageCode, 'en');
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('App language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(CacheHelper.getDataString(key: 'app_language_code'), 'en');

    final restoredCubit = LanguageCubit();
    expect(restoredCubit.state.languageCode, 'en');
    await restoredCubit.close();
  });

  testWidgets('patient sign-in copy follows the selected locale', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: PatientLoginHero()),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Patient sign in'), findsOneWidget);
    expect(
      find.text('Securely access your appointments and medical record.'),
      findsOneWidget,
    );
  });
}
