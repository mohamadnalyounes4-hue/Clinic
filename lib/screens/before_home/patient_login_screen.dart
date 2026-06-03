import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/user_cubit.dart';
import 'package:nabad/Cubits/user_state.dart';
import 'package:nabad/core/router/app_router.dart';
import 'package:nabad/core/theme/nabad_colors.dart';
import 'package:nabad/screens/HomePage_patient/homepage_p.dart';
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
    if (password.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserCubit, UserState>(
      listener: (context, state) {
        if (state is LoginSuccessPatient) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PatientHomePage()),
          );
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
        } else if (state is LoginError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
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
