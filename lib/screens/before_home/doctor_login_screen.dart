import 'package:flutter/material.dart';
import 'package:nabad/core/theme/nabad_colors.dart';
import 'package:nabad/screens/HomePage_doctor/homepage_d.dart';
import 'package:nabad/widgets/patient_login/country_code.dart';
import 'package:nabad/widgets/patient_login/patient_login_card.dart';
import 'package:nabad/widgets/soft_ring.dart';

class DoctorLoginScreen extends StatefulWidget {
  const DoctorLoginScreen({super.key});

  @override
  State<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedCountryCode = '+963';
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;

    final String fullPhoneNumber =
        '$_selectedCountryCode${_phoneController.text}';
    debugPrint('Doctor login: $fullPhoneNumber, rememberMe: $_rememberMe');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DoctorHomePage()),
    );
  }

  String? _validatePhone(String? value) {
    final String phone = value?.trim() ?? '';
    if (phone.isEmpty) {
      return 'أدخل رقم الهاتف';
    }
    if (phone.length != 9) {
      return 'رقم الهاتف يجب أن يكون 9 أرقام';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final String password = value ?? '';
    if (password.isEmpty) {
      return 'أدخل كلمة المرور';
    }
    if (password.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: NabadColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned(top: 74, right: -72, child: SoftRing(size: 210)),
              Positioned(
                left: -40,
                bottom: 90,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.055,
                    child: Image.asset(
                      'assets/images/logoIcon.png',
                      width: 190,
                      height: 190,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 26),
                children: [
                  const SizedBox(height: 20),
                  const _DoctorLoginHero(),
                  const SizedBox(height: 28),
                  PatientLoginCard(
                    formKey: _formKey,
                    phoneController: _phoneController,
                    passwordController: _passwordController,
                    countryCodes: CountryCodes.defaultCodes,
                    selectedCountryCode: _selectedCountryCode,
                    obscurePassword: _obscurePassword,
                    rememberMe: _rememberMe,
                    onCountryChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedCountryCode = value);
                    },
                    onTogglePassword: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    onRememberChanged: (value) {
                      setState(() => _rememberMe = value ?? false);
                    },
                    validatePhone: _validatePhone,
                    validatePassword: _validatePassword,
                    onLogin: _login,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorLoginHero extends StatelessWidget {
  const _DoctorLoginHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NabadColors.primary,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: NabadColors.primary.withAlpha(38),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أهلاً بعودتك',
                  style: TextStyle(
                    color: Colors.white.withAlpha(220),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'تسجيل دخول الطبيب',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ادخل إلى مواعيدك وملفات المرضى ضمن مركز العيادات.',
                  style: TextStyle(
                    color: Colors.white.withAlpha(215),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(235),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: NabadColors.primary,
              size: 38,
            ),
          ),
        ],
      ),
    );
  }
}
