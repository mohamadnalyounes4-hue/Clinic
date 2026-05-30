import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nabad/core/theme/nabad_colors.dart';
import 'package:nabad/widgets/patient_login/country_code.dart';

class PatientLoginCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final List<CountryCode> countryCodes;
  final String selectedCountryCode;
  final bool obscurePassword;
  final bool rememberMe;
  final ValueChanged<String?> onCountryChanged;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool?> onRememberChanged;
  final FormFieldValidator<String> validatePhone;
  final FormFieldValidator<String> validatePassword;
  final VoidCallback? onLogin; // nullable لدعم isLoading

  const PatientLoginCard({
    super.key,
    required this.formKey,
    required this.phoneController,
    required this.passwordController,
    required this.countryCodes,
    required this.selectedCountryCode,
    required this.obscurePassword,
    required this.rememberMe,
    required this.onCountryChanged,
    required this.onTogglePassword,
    required this.onRememberChanged,
    required this.validatePhone,
    required this.validatePassword,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(235),
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
              'بيانات الدخول',
              style: TextStyle(color: NabadColors.darkText, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 18),
            const _FieldLabel(label: 'رقم الهاتف'),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 118,
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedCountryCode,
                    borderRadius: BorderRadius.circular(18),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    decoration: _fieldDecoration(),
                    items: countryCodes.map((country) {
                      return DropdownMenuItem<String>(
                        value: country.code,
                        child: Text(
                          country.code,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(color: NabadColors.deepTeal, fontWeight: FontWeight.w800),
                        ),
                      );
                    }).toList(),
                    onChanged: onCountryChanged,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: phoneController,
                    validator: validatePhone,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: _fieldDecoration(
                      hintText: '10 أرقام',
                      counterText: '',
                      prefixIcon: Icons.phone_rounded,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _FieldLabel(label: 'كلمة المرور'),
            const SizedBox(height: 8),
            TextFormField(
              controller: passwordController,
              validator: validatePassword,
              obscureText: obscurePassword,
              decoration: _fieldDecoration(
                hintText: 'أدخل كلمة المرور',
                prefixIcon: Icons.lock_rounded,
                suffix: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(
                    obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    color: NabadColors.mutedText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              child: CheckboxListTile(
                value: rememberMe,
                onChanged: onRememberChanged,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: NabadColors.primary,
                title: const Text(
                  'تذكرني',
                  style: TextStyle(color: NabadColors.deepTeal, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NabadColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  'تسجيل الدخول',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static InputDecoration _fieldDecoration({
    String? hintText,
    String? counterText,
    IconData? prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hintText,
      counterText: counterText,
      filled: true,
      fillColor: const Color(0xFFF4FBFC),
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, color: NabadColors.primary),
      suffixIcon: suffix,
      hintStyle: const TextStyle(color: NabadColors.mutedText, fontWeight: FontWeight.w600),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: NabadColors.primary.withAlpha(18))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: NabadColors.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFD94B4B), width: 1.2)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFD94B4B), width: 1.5)),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(color: NabadColors.deepTeal, fontSize: 13.5, fontWeight: FontWeight.w900));
  }
}