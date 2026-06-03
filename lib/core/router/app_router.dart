import 'package:flutter/material.dart';
import 'package:nabad/screens/HomePage_patient/homepage_p.dart';
import 'package:nabad/screens/before_home/account_type_screen.dart';
import 'package:nabad/screens/before_home/doctor_login_screen.dart';
import 'package:nabad/screens/before_home/health_information_screen.dart';
import 'package:nabad/screens/before_home/welcome_interface.dart';
import 'package:nabad/screens/before_home/otp_code_screen.dart';
import 'package:nabad/screens/before_home/patient_login_screen.dart';
import 'package:nabad/screens/before_home/register_screen.dart';
import 'package:nabad/screens/HomePage_doctor/homepage_d.dart';

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
  static const String doctorHome = '/doctor_home';
  static const String patientHome = '/patient_home';
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
      case AppRoutes.doctorHome:
        return MaterialPageRoute(builder: (_) => const DoctorHomePage());
      case AppRoutes.patientHome:
        return MaterialPageRoute(builder: (_) => const PatientHomePage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
