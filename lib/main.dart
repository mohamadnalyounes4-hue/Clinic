import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/user_cubit.dart';
import 'package:nabad/Repositories/user_repository.dart';
import 'package:nabad/core/Api/dio_consumer.dart';
import 'package:nabad/core/Cache/cache_helper.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheHelper.init();
  runApp(const NabadApp());
}

class NabadApp extends StatelessWidget {
  const NabadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => UserCubit(
            userRepository: UserRepository(
              api: DioConsumer(dio: Dio()),
            ),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.welcome,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}