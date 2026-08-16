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
                    maxLength: 20,
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
                    maxLength: 20,
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
  final int? maxLength;

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
    this.maxLength,
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
          maxLength: maxLength,
          decoration: InputDecoration(
            counterText: maxLength != null ? '' : null,
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
