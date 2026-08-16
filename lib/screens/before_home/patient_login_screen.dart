import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/cubits/user_cubit.dart';
import 'package:nabad/Cubits/states/user_state.dart';
import 'package:nabad/core/Api/end_points.dart';
import 'package:nabad/core/Cache/cache_helper.dart';
import 'package:nabad/core/router/app_router.dart';
import 'package:nabad/core/theme/nabad_colors.dart';
import 'package:nabad/screens/HomePage_patient/homepage_p.dart';
import 'package:nabad/screens/before_home/health_information_screen.dart';
import 'package:nabad/widgets/patient_login/country_code.dart';
import 'package:nabad/widgets/patient_login/create_account_prompt.dart';
import 'package:nabad/widgets/patient_login/patient_login_card.dart';
import 'package:nabad/widgets/patient_login/patient_login_hero.dart';
import 'package:nabad/widgets/soft_ring.dart';

class PatientLoginScreen extends StatefulWidget {
  const PatientLoginScreen({super.key});

  @override
  State<PatientLoginScreen> createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
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

    context.read<UserCubit>().login(
      phone: _phoneController.text.trim(), // بدون كود الدولة
      password: _passwordController.text,
    );
  }

  String? _validatePhone(String? value) {
    final String phone = value?.trim() ?? '';
    if (phone.isEmpty) return 'أدخل رقم الهاتف';
    if (phone.length != 10) return 'رقم الهاتف يجب أن يكون 10 أرقام';
    return null;
  }

  String? _validatePassword(String? value) {
    final String password = value ?? '';
    if (password.isEmpty) return 'أدخل كلمة المرور';
    // الباك إند يطلب 8 أحرف على الأقل لكلمة المرور (نفس شرط شاشة التسجيل).
    if (password.length < 8) return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserCubit, UserState>(
      listener: (context, state) {
        if (state is LoginSuccessPatient) {
          // قبل ما نفتح الهوم، نتأكد إن ملف المريض مكتمل (gender/birth_date/
          // address)، زي ما التوثيق بيطلب، بدل ما نسمح له يوصل للحجز بملف ناقص.
          context.read<UserCubit>().getPatientProfile();
        }
        if (state is LoginSuccessDoctor) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'هذا الحساب مسجل كطبيب، يرجى تسجيل الدخول كطبيب',
              ),
              backgroundColor: Colors.orange.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is PatientProfileSuccess) {
          final patient = state.patient;
          final bool isIncomplete = patient.gender == null ||
              patient.birthDate == null ||
              patient.address == null;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => isIncomplete
                  ? const HealthInformationScreen()
                  : const PatientHomePage(),
            ),
          );
        } else if (state is PatientProfileError) {
          // ما قدرناش نتأكد من اكتمال الملف (مثلاً مشكلة شبكة)؛ ما لازم نحبس
          // المستخدم هون، منسمحله يدخل عالهوم عادي.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PatientHomePage()),
          );
        } else if (state is LoginError) {
          if (state.statusCode == 403) {
            // البريد غير مؤكد -> حوّله لشاشة OTP مع البريد المحفوظ من التسجيل.
            final String? savedEmail = CacheHelper.getDataString(
              key: ApiKey.email,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.orange.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pushNamed(
              context,
              AppRoutes.otpCode,
              arguments: savedEmail,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: NabadColors.background,
          body: SafeArea(
            child: Stack(
              children: [
                const Positioned(
                  top: 74,
                  right: -72,
                  child: SoftRing(size: 210),
                ),
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
                BlocBuilder<UserCubit, UserState>(
                  builder: (context, state) {
                    final isLoading = state is LoginLoading;
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 26),
                      children: [
                        const SizedBox(height: 20),
                        const PatientLoginHero(),
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
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                          onRememberChanged: (value) {
                            setState(() => _rememberMe = value ?? false);
                          },
                          validatePhone: _validatePhone,
                          validatePassword: _validatePassword,
                          onLogin: isLoading ? () {} : _login,
                        ),
                        if (isLoading) ...[
                          const SizedBox(height: 24),
                          const Center(child: CircularProgressIndicator()),
                        ],
                        const SizedBox(height: 22),
                        CreateAccountPrompt(
                          onCreateAccount: () {
                            Navigator.pushNamed(context, AppRoutes.register);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
