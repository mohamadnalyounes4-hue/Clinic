import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/department_cubit.dart';
import 'package:nabad/Cubits/doctor_cubit.dart';
import 'package:nabad/Cubits/user_cubit.dart';
import 'package:nabad/Repositories/user_repository.dart';
import 'package:nabad/core/Api/dio_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';
import 'package:nabad/core/Cache/cache_helper.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheHelper.init();

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

  runApp(NabadApp(initialRoute: initialRoute));
}

class NabadApp extends StatelessWidget {
  final String initialRoute;

  const NabadApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final dio = Dio();
    final api = DioConsumer(dio: dio);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => UserCubit(userRepository: UserRepository(api: api)),
        ),
        BlocProvider(create: (_) => DepartmentCubit(api: api)),
        BlocProvider(create: (_) => DoctorCubit(api: api)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        initialRoute: initialRoute,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
