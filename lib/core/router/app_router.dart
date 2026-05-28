import 'package:flutter/material.dart';
import 'package:nabad/screens/account_type_screen.dart';
import 'package:nabad/screens/doctor_login_screen.dart';
import 'package:nabad/screens/health_information_screen.dart';
import 'package:nabad/screens/welcome_interface.dart';
import 'package:nabad/screens/otp_code_screen.dart';
import 'package:nabad/screens/patient_login_screen.dart';
import 'package:nabad/screens/register_screen.dart';

class AppRoutes {
  static const String welcome = '/';
  static const String home = '/home';
  static const String accountType = '/account_type';
  static const String doctorLogin = '/doctor_login';
  static const String patientLogin = '/patient_login';
  static const String register = '/register';
  static const String otpCode = '/otp_code';
  static const String healthInformation = '/health_information';
  static const String login = '/login';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeInterface());
      case AppRoutes.accountType:
        return MaterialPageRoute(builder: (_) => const AccountTypeScreen());
      case AppRoutes.doctorLogin:
        return MaterialPageRoute(builder: (_) => const DoctorLoginScreen());
      case AppRoutes.patientLogin:
        return MaterialPageRoute(builder: (_) => const PatientLoginScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case AppRoutes.otpCode:
        return MaterialPageRoute(
          builder: (_) => OtpCodeScreen(email: settings.arguments as String?),
        );
      case AppRoutes.healthInformation:
        return MaterialPageRoute(
          builder: (_) => const HealthInformationScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
