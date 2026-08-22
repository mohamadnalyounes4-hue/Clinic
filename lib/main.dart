import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nabad/Cubits/cubits/appointment_cubit.dart';
import 'package:nabad/Cubits/cubits/medicine_reminder_cubit.dart';
import 'package:nabad/Cubits/cubits/department_cubit.dart';
import 'package:nabad/Cubits/cubits/doctor_cubit.dart';
import 'package:nabad/Cubits/cubits/doctor_dashboard_cubit.dart';
import 'package:nabad/Cubits/cubits/patient_medical_record_cubit.dart';
import 'package:nabad/Cubits/cubits/patient_notification_cubit.dart';
import 'package:nabad/Cubits/cubits/points_cubit.dart';
import 'package:nabad/Cubits/cubits/points_history_cubit.dart';
import 'package:nabad/Cubits/cubits/user_cubit.dart';
import 'package:nabad/Cubits/cubits/wallet_cubit.dart';
import 'package:nabad/Cubits/cubits/theme_cubit.dart';
import 'package:nabad/Cubits/cubits/language_cubit.dart';
import 'package:nabad/Cubits/cubits/support_cubit.dart';
import 'package:nabad/Repositories/support_repository.dart';
import 'package:nabad/Repositories/notification_repository.dart';
import 'package:nabad/Repositories/user_repository.dart';
import 'package:nabad/Services/support_service.dart';
import 'package:nabad/core/Api/dio_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';
import 'package:nabad/core/Cache/cache_helper.dart';
import 'package:nabad/core/notifications/medicine_reminder_service.dart';
import 'package:nabad/core/notifications/push_notification_service.dart';
import 'package:nabad/core/localization/app_localizations.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'core/router/app_router.dart';
import 'core/theme/nabad_theme.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheHelper.init();
  await MedicineReminderService.instance.initialize();
  final api = DioConsumer(dio: Dio());
  final notificationRepository = NotificationRepository(api: api);
  await PushNotificationService.instance.initialize(
    repository: notificationRepository,
    navigatorKey: rootNavigatorKey,
  );

  final token = CacheHelper.getData(key: ApiKey.token);
  final role = CacheHelper.getData(key: ApiKey.role);

  String initialRoute;
  if (token != null) {
    initialRoute = role == 'doctor'
        ? AppRoutes.doctorHome
        : AppRoutes.patientHome;
  } else {
    initialRoute = AppRoutes.welcome;
  }

  runApp(NabadApp(initialRoute: initialRoute, api: api));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PushNotificationService.instance.onNotificationsChanged = () async {
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        await context.read<PatientNotificationCubit>().loadUnreadCount();
      }
    };
    PushNotificationService.instance.processPendingNavigation();
  });
}

class NabadApp extends StatelessWidget {
  final String initialRoute;
  final ApiConsumer api;

  const NabadApp({super.key, required this.initialRoute, required this.api});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => UserCubit(
            userRepository: UserRepository(api: api),
            pushNotificationService: PushNotificationService.instance,
          ),
        ),
        BlocProvider(create: (_) => DepartmentCubit(api: api)),
        BlocProvider(create: (_) => DoctorCubit(api: api)),
        BlocProvider(create: (_) => DoctorDashboardCubit(api: api)),
        BlocProvider(create: (_) => AppointmentCubit(api: api)),
        BlocProvider(
          create: (_) =>
              MedicineReminderCubit(service: MedicineReminderService.instance),
        ),
        BlocProvider(create: (_) => PatientMedicalRecordCubit(api: api)),
        BlocProvider(create: (_) => PatientNotificationCubit(api: api)),
        BlocProvider(
          create: (_) => SupportCubit(
            repository: SupportRepository(service: SupportService(api: api)),
          ),
        ),
        BlocProvider(create: (_) => PointsCubit(api: api)),
        BlocProvider(create: (_) => PointsHistoryCubit(api: api)),
        BlocProvider(create: (_) => WalletCubit(api: api)),
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => LanguageCubit()),
      ],
      child: BlocBuilder<LanguageCubit, Locale>(
        builder: (context, locale) => BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) => MaterialApp(
            navigatorKey: rootNavigatorKey,
            debugShowCheckedModeBanner: false,
            theme: NabadTheme.light,
            darkTheme: NabadTheme.dark,
            themeMode: themeMode,
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: initialRoute,
            onGenerateRoute: AppRouter.generateRoute,
          ),
        ),
      ),
    );
  }
}
