import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabad/Cubits/cubits/doctor_dashboard_cubit.dart';
import 'package:nabad/Cubits/cubits/language_cubit.dart';
import 'package:nabad/Cubits/cubits/theme_cubit.dart';
import 'package:nabad/Cubits/cubits/user_cubit.dart';
import 'package:nabad/Repositories/user_repository.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';
import 'package:nabad/core/Cache/cache_helper.dart';
import 'package:nabad/core/localization/app_localizations.dart';
import 'package:nabad/screens/HomePage_doctor/homepage_d.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'doctor dashboard renders at a common phone size without overflow',
    (tester) async {
      SharedPreferences.setMockInitialValues({ApiKey.id: 12});
      await CacheHelper.init();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = _FakeApi();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => DoctorDashboardCubit(api: api)),
            BlocProvider(
              create: (_) =>
                  UserCubit(userRepository: UserRepository(api: api)),
            ),
          ],
          child: const MaterialApp(home: DoctorHomePage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('سمير المنصوري', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('إجراءات سريعة'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('مواعيدي').last);
      await tester.pumpAndSettle();
      expect(find.text('جدول اليوم وجميع المراجعين'), findsOneWidget);
      expect(find.text('إجمالي المواعيد'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('بدء المعاينة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('بدء المعاينة'));
      await tester.pumpAndSettle();
      expect(find.text('إتمام الزيارة'), findsOneWidget);
      expect(find.text('أدخل التشخيص الرئيسي للحالة... *'), findsOneWidget);
      expect(tester.takeException(), isNull);

      for (var index = 0; index < 3; index++) {
        await tester.drag(find.byType(ListView).last, const Offset(0, -500));
        await tester.pumpAndSettle();
        if (find.text('إضافة دواء').evaluate().isNotEmpty) break;
      }
      await tester.tap(find.text('إضافة دواء'));
      await tester.pumpAndSettle();
      expect(find.text('اسم الدواء *'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'اسم الدواء *'),
        'باراسيتامول',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'الجرعة *'),
        '500mg',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'التكرار (مثال: كل 12 ساعة) *'),
        'كل 8 ساعات',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'المدة (مثال: 7 أيام) *'),
        '3 أيام',
      );
      await tester.ensureVisible(find.text('إضافة الدواء'));
      await tester.tap(find.text('إضافة الدواء'));
      await tester.pumpAndSettle();

      expect(find.text('باراسيتامول 500mg'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('doctor can open settings and switch the whole app language', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      ApiKey.id: 12,
      'app_language_code': 'en',
    });
    await CacheHelper.init();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final api = _FakeApi();
    final languageCubit = LanguageCubit();
    final themeCubit = ThemeCubit();
    addTearDown(languageCubit.close);
    addTearDown(themeCubit.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => DoctorDashboardCubit(api: api)),
          BlocProvider(
            create: (_) => UserCubit(userRepository: UserRepository(api: api)),
          ),
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
            home: const DoctorHomePage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quick actions'), findsOneWidget);
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    await tester.ensureVisible(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('App language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.text('Switch to Arabic'));
    await tester.pumpAndSettle();
    expect(languageCubit.state.languageCode, 'ar');
    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('لغة التطبيق'), findsOneWidget);
  });
}

class _FakeApi extends ApiConsumer {
  @override
  Future<dynamic> get(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async {
    if (path == EndPoints.currentUser) {
      return {
        'data': {
          'id': 12,
          'first_name': 'سمير',
          'last_name': 'المنصوري',
          'email': 'doctor@example.com',
          'phone': '0999999999',
          'role': 'doctor',
        },
      };
    }
    if (path == EndPoints.allDoctors) {
      return {
        'data': [
          {
            'id': 8,
            'user_id': 12,
            'first_name': 'سمير',
            'last_name': 'المنصوري',
            'specialization': 'طب القلب',
          },
        ],
      };
    }
    if (path == EndPoints.myDoctorAppointments) {
      final today = DateTime.now();
      final date =
          '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';
      return {
        'data': [
          {
            'id': 44,
            'appointment_date': date,
            'appointment_time': '23:30',
            'status': 'confirmed',
            'patient': {
              'id': 5,
              'user': {'first_name': 'أحمد', 'last_name': 'العلي'},
            },
          },
        ],
      };
    }
    if (path == EndPoints.notifications) return {'data': <dynamic>[]};
    if (path == EndPoints.unreadNotificationsCount) return {'count': 3};
    if (path == EndPoints.doctorMedicalRecords) return {'data': <dynamic>[]};
    if (path == EndPoints.prescriptions) return {'data': <dynamic>[]};
    return <String, dynamic>{};
  }

  @override
  Future<dynamic> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async => <String, dynamic>{};

  @override
  Future<dynamic> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async => <String, dynamic>{};

  @override
  Future<dynamic> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async => <String, dynamic>{};
}
