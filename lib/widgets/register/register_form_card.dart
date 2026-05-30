import 'package:flutter/material.dart';
import 'package:nabad/core/theme/nabad_colors.dart';

class RegisterFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final String passwordValue;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final FormFieldValidator<String> validateFirstName;
  final FormFieldValidator<String> validateLastName;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePhone;
  final FormFieldValidator<String> validatePassword;
  final FormFieldValidator<String> validateConfirmPassword;
  final VoidCallback onCreateAccount;

  const RegisterFormCard({
    super.key,
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.passwordValue,
    required this.onPasswordChanged,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.validateFirstName,
    required this.validateLastName,
    required this.validateEmail,
    required this.validatePhone,
    required this.validatePassword,
    required this.validateConfirmPassword,
    required this.onCreateAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(238),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withAlpha(230)),
        boxShadow: [
          BoxShadow(
            color: NabadColors.primary.withAlpha(20),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'المعلومات الشخصية',
              style: TextStyle(
                color: NabadColors.darkText,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _RegisterTextField(
                    controller: firstNameController,
                    label: 'الاسم الأول',
                    hintText: '',
                    icon: Icons.person_rounded,
                    validator: validateFirstName,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RegisterTextField(
                    controller: lastNameController,
                    label: 'الاسم الأخير',
                    hintText: '',
                    icon: Icons.badge_rounded,
                    validator: validateLastName,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _RegisterTextField(
              controller: emailController,
              label: 'البريد الإلكتروني',
              hintText: 'example@mail.com',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              validator: validateEmail,
            ),
            const SizedBox(height: 14),
            _RegisterTextField(
              controller: phoneController,
              label: 'رقم الهاتف',
              hintText: '--------09',
              icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              validator: validatePhone,
            ),
            const SizedBox(height: 14),
            _RegisterTextField(
              controller: passwordController,
              label: 'كلمة السر',
              hintText: 'أدخل كلمة السر',
              icon: Icons.lock_rounded,
              obscureText: obscurePassword,
              validator: validatePassword,
              onChanged: onPasswordChanged,
              suffix: IconButton(
                onPressed: onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: NabadColors.mutedText,
                ),
              ),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              // child: passwordValue.isEmpty
              //     ? const SizedBox.shrink(key: ValueKey('empty-strength'))
              //     : _PasswordStrengthMeter(password: passwordValue),
            ),
            const SizedBox(height: 14),
            _RegisterTextField(
              controller: confirmPasswordController,
              label: 'تأكيد كلمة السر',
              hintText: 'أعد إدخال كلمة السر',
              icon: Icons.verified_user_rounded,
              obscureText: obscureConfirmPassword,
              validator: validateConfirmPassword,
              suffix: IconButton(
                onPressed: onToggleConfirmPassword,
                icon: Icon(
                  obscureConfirmPassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: NabadColors.mutedText,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: onCreateAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NabadColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'إنشاء الحساب',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextDirection? textDirection;
  final Widget? suffix;
  final FormFieldValidator<String> validator;
  final ValueChanged<String>? onChanged;

  const _RegisterTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.textDirection,
    this.suffix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: NabadColors.deepTeal,
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          onChanged: onChanged,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textDirection: textDirection,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: const Color(0xFFF4FBFC),
            prefixIcon: Icon(icon, color: NabadColors.primary),
            suffixIcon: suffix,
            hintStyle: const TextStyle(
              color: NabadColors.mutedText,
              fontWeight: FontWeight.w600,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: NabadColors.primary.withAlpha(18)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: NabadColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Color(0xFFD94B4B),
                width: 1.2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Color(0xFFD94B4B),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// class _PasswordStrengthMeter extends StatelessWidget {
//   final String password;

//   const _PasswordStrengthMeter({required this.password});

//   bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(password);
//   bool get _hasLowercase => RegExp(r'[a-z]').hasMatch(password);
//   bool get _hasNumber => RegExp(r'\d').hasMatch(password);
//   bool get _hasSymbol =>
//       RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=/\\[\]؛،~`]').hasMatch(password);
//   bool get _hasIdealLength => password.length > 15;

//   int get _score {
//     int score = 0;
//     if (_hasUppercase) score++;
//     if (_hasLowercase) score++;
//     if (_hasNumber) score++;
//     if (_hasSymbol) score++;
//     if (password.length >= 8) score++;
//     if (_hasIdealLength) score++;
//     return score;
//   }

//   double get _progress {
//     if (password.isEmpty) return 0;
//     return (_score / 6).clamp(0.0, 1.0);
//   }

//   Color get _color {
//     if (_score <= 2) return const Color(0xFFD94B4B);
//     if (_score <= 4) return const Color(0xFFE2A228);
//     if (_score == 5) return const Color(0xFF2FA6A2);
//     return NabadColors.primary;
//   }

//   String get _label {
//     if (password.isEmpty) return 'ابدأ بكتابة كلمة المرور';
//     if (_score <= 2) return 'ضعيفة';
//     if (_score <= 4) return 'متوسطة';
//     if (_score == 5) return 'قوية';
//     return 'مثالية';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 220),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF4FBFC),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: _color.withAlpha(password.isEmpty ? 18 : 55)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Row(
//             children: [
//               const Text(
//                 'قوة كلمة المرور',
//                 style: TextStyle(
//                   color: NabadColors.deepTeal,
//                   fontSize: 12.5,
//                   fontWeight: FontWeight.w900,
//                 ),
//               ),
//               const Spacer(),
//               AnimatedDefaultTextStyle(
//                 duration: const Duration(milliseconds: 180),
//                 style: TextStyle(
//                   color: _color,
//                   fontSize: 12.5,
//                   fontWeight: FontWeight.w900,
//                 ),
//                 child: Text(_label),
//               ),
//             ],
//           ),
//           const SizedBox(height: 9),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(999),
//             child: LinearProgressIndicator(
//               value: _progress,
//               minHeight: 7,
//               backgroundColor: NabadColors.primary.withAlpha(18),
//               valueColor: AlwaysStoppedAnimation<Color>(_color),
//             ),
//           ),
//           const SizedBox(height: 10),
//           Wrap(
//             spacing: 7,
//             runSpacing: 7,
//             children: [
//               _PasswordRuleChip(label: 'حرف كبير', isMet: _hasUppercase),
//               _PasswordRuleChip(label: 'حرف صغير', isMet: _hasLowercase),
//               _PasswordRuleChip(label: 'رقم', isMet: _hasNumber),
//               _PasswordRuleChip(label: 'رمز', isMet: _hasSymbol),
//               _PasswordRuleChip(label: '8+ أحرف', isMet: password.length >= 8),
//               _PasswordRuleChip(label: 'مثالية 15+', isMet: _hasIdealLength),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _PasswordRuleChip extends StatelessWidget {
//   final String label;
//   final bool isMet;

//   const _PasswordRuleChip({required this.label, required this.isMet});

//   @override
//   Widget build(BuildContext context) {
//     final Color color = isMet ? NabadColors.primary : NabadColors.mutedText;

//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 180),
//       padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
//       decoration: BoxDecoration(
//         color: isMet ? NabadColors.primary.withAlpha(22) : Colors.white,
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: color.withAlpha(isMet ? 60 : 28)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             isMet ? Icons.check_rounded : Icons.circle_outlined,
//             size: 14,
//             color: color,
//           ),
//           const SizedBox(width: 5),
//           Text(
//             label,
//             style: TextStyle(
//               color: color,
//               fontSize: 11.5,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
