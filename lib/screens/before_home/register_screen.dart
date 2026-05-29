import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
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
  static final Set<String> _registeredEmails = <String>{};

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  Uint8List? _profileImageBytes;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _createAccount() {
    if (!_formKey.currentState!.validate()) return;

    if (_profileImageBytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى اختيار صورة شخصية')));
      return;
    }

    final String normalizedEmail = _emailController.text.trim().toLowerCase();
    if (_registeredEmails.contains(normalizedEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا البريد الإلكتروني مستخدم بالفعل')),
      );
      return;
    }

    _registeredEmails.add(normalizedEmail);
    Navigator.pushNamed(context, AppRoutes.otpCode, arguments: normalizedEmail);
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;

      final Uint8List bytes = await image.readAsBytes();
      if (!mounted) return;

      setState(() {
        _profileImageBytes = bytes;
      });
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح الاستديو، أعد تشغيل التطبيق وحاول مجددًا'),
        ),
      );
    }
  }

  String? _requiredValidator(String? value, String label) {
    if ((value ?? '').trim().isEmpty) {
      return '$label مطلوب';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final String email = (value ?? '').trim();
    if (email.isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    final bool isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!isValid) {
      return 'أدخل بريد إلكتروني صحيح';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    final String password = value ?? '';
    if (password.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (password.length < 8) {
      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'يجب أن تحتوي على حرف كبير واحد على الأقل';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'يجب أن تحتوي على حرف صغير واحد على الأقل';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'يجب أن تحتوي على رقم واحد على الأقل';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\[\]؛،~`]').hasMatch(password)) {
      return 'يجب أن تحتوي على رمز واحد على الأقل';
    }
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    final String confirmPassword = value ?? '';
    if (confirmPassword.isEmpty) {
      return 'تأكيد كلمة المرور مطلوب';
    }
    if (confirmPassword != _passwordController.text) {
      return 'كلمتا المرور غير متطابقتين';
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
              LayoutBuilder(
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
                            imageBytes: _profileImageBytes,
                            onPickImage: _pickProfileImage,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 34, 22, 0),
                            child: RegisterFormCard(
                              formKey: _formKey,
                              firstNameController: _firstNameController,
                              lastNameController: _lastNameController,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              confirmPasswordController:
                                  _confirmPasswordController,
                              obscurePassword: _obscurePassword,
                              obscureConfirmPassword: _obscureConfirmPassword,
                              passwordValue: _passwordController.text,
                              onPasswordChanged: (_) => setState(() {}),
                              onTogglePassword: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                              onToggleConfirmPassword: () {
                                setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                );
                              },
                              validateFirstName: (value) =>
                                  _requiredValidator(value, 'الاسم الأول'),
                              validateLastName: (value) =>
                                  _requiredValidator(value, 'الاسم الأخير'),
                              validateEmail: _emailValidator,
                              validatePassword: _passwordValidator,
                              validateConfirmPassword:
                                  _confirmPasswordValidator,
                              onCreateAccount: _createAccount,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
