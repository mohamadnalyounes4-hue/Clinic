import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/user_cubit.dart';
import 'package:nabad/Cubits/user_state.dart';
import 'package:nabad/core/router/app_router.dart';
import 'package:nabad/core/theme/nabad_colors.dart';
import 'package:nabad/widgets/register/register_form_card.dart';
import 'package:nabad/widgets/register/register_header.dart';
import 'package:nabad/widgets/soft_ring.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _createAccount() {
    if (!_formKey.currentState!.validate()) return;

    context.read<UserCubit>().register(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        );
  }

  String? _requiredValidator(String? value, String label) {
    if ((value ?? '').trim().isEmpty) return '$label مطلوب';
    return null;
  }

  String? _emailValidator(String? value) {
    final String email = (value ?? '').trim();
    if (email.isEmpty) return 'البريد الإلكتروني مطلوب';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'أدخل بريد إلكتروني صحيح';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final String phone = (value ?? '').trim();
    if (phone.isEmpty) return 'رقم الهاتف مطلوب';
    if (phone.length != 10) return 'رقم الهاتف يجب أن يكون 10 أرقام';
    return null;
  }

  String? _passwordValidator(String? value) {
    final String password = value ?? '';
    if (password.isEmpty) return 'كلمة المرور مطلوبة';
    if (password.length < 8) return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    // if (!RegExp(r'[A-Z]').hasMatch(password)) return 'يجب أن تحتوي على حرف كبير واحد على الأقل';
    // if (!RegExp(r'[a-z]').hasMatch(password)) return 'يجب أن تحتوي على حرف صغير واحد على الأقل';
    // if (!RegExp(r'\d').hasMatch(password)) return 'يجب أن تحتوي على رقم واحد على الأقل';
    // if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\[\]؛،~`]').hasMatch(password)) {
    //   return 'يجب أن تحتوي على رمز واحد على الأقل';
    // }
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if ((value ?? '').isEmpty) return 'تأكيد كلمة المرور مطلوب';
    if (value != _passwordController.text) return 'كلمتا المرور غير متطابقتين';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserCubit, UserState>(
      listener: (context, state) {
        if (state is RegisterSuccess) {
          Navigator.pushNamed(
            context,
            AppRoutes.otpCode,
            arguments: _emailController.text.trim(),
          );
        } else if (state is RegisterError) {
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
                const Positioned(top: 90, right: -72, child: SoftRing(size: 220)),
                Positioned(
                  left: -42,
                  bottom: 92,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.05,
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
                    final isLoading = state is RegisterLoading;
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 26),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - 26,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                RegisterHeader(
                                  onBack: () => Navigator.maybePop(context),
                                  imageBytes: null,
                                  onPickImage: () {},
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(22, 34, 22, 0),
                                  child: RegisterFormCard(
                                    formKey: _formKey,
                                    firstNameController: _firstNameController,
                                    lastNameController: _lastNameController,
                                    emailController: _emailController,
                                    phoneController: _phoneController,
                                    passwordController: _passwordController,
                                    confirmPasswordController: _confirmPasswordController,
                                    obscurePassword: _obscurePassword,
                                    obscureConfirmPassword: _obscureConfirmPassword,
                                    passwordValue: _passwordController.text,
                                    onPasswordChanged: (_) => setState(() {}),
                                    onTogglePassword: () {
                                      setState(() => _obscurePassword = !_obscurePassword);
                                    },
                                    onToggleConfirmPassword: () {
                                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                    },
                                    validateFirstName: (value) => _requiredValidator(value, 'الاسم الأول'),
                                    validateLastName: (value) => _requiredValidator(value, 'الاسم الأخير'),
                                    validateEmail: _emailValidator,
                                    validatePhone: _phoneValidator,
                                    validatePassword: _passwordValidator,
                                    validateConfirmPassword: _confirmPasswordValidator,
                                    onCreateAccount: isLoading ? () {} : _createAccount,
                                  ),
                                ),
                                if (isLoading) ...[
                                  const SizedBox(height: 24),
                                  const Center(child: CircularProgressIndicator()),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
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