import 'package:flutter/material.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(const NabadApp());
}

class NabadApp extends StatelessWidget {
  const NabadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.welcome,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
