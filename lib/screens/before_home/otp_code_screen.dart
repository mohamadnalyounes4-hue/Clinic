import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/user_cubit.dart';
import 'package:nabad/Cubits/user_state.dart';
import 'package:nabad/core/router/app_router.dart';
import 'package:nabad/core/theme/nabad_colors.dart';
import 'package:nabad/widgets/soft_ring.dart';

class OtpCodeScreen extends StatefulWidget {
  final String? email;

  const OtpCodeScreen({super.key, this.email});

  @override
  State<OtpCodeScreen> createState() => _OtpCodeScreenState();
}

class _OtpCodeScreenState extends State<OtpCodeScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _verifyCode() {
    if (_code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل رمز التحقق المؤلف من 6 أرقام')),
      );
      return;
    }

    context.read<UserCubit>().verifyOtp(
          email: widget.email ?? '',
          code: _code,
        );
  }

  void _resendCode() {
    if (widget.email == null) return;
    context.read<UserCubit>().resendOtp(email: widget.email!);
  }

  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < _focusNodes.length - 1) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    }
    if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserCubit, UserState>(
      listener: (context, state) {
        if (state is VerifyOtpSuccess) {
          Navigator.pushReplacementNamed(context, AppRoutes.healthInformation);
        } else if (state is VerifyOtpError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is ResendOtpSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إرسال الرمز مجدداً'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is ResendOtpError) {
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
                const Positioned(top: 84, right: -70, child: SoftRing(size: 220)),
                Positioned(
                  left: -42,
                  bottom: 92,
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
                    final isVerifying = state is VerifyOtpLoading;
                    final isResending = state is ResendOtpLoading;

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight - 46),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: IconButton.filled(
                                    onPressed: () => Navigator.maybePop(context),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.white.withAlpha(220),
                                      foregroundColor: NabadColors.primary,
                                      fixedSize: const Size(46, 46),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    icon: const Icon(Icons.arrow_forward_rounded),
                                  ),
                                ),
                                SizedBox(height: constraints.maxHeight * 0.12),
                                Container(
                                  padding: const EdgeInsets.all(22),
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        width: 76,
                                        height: 76,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: NabadColors.primary.withAlpha(24),
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        child: const Icon(
                                          Icons.mark_email_read_rounded,
                                          color: NabadColors.primary,
                                          size: 38,
                                        ),
                                      ),
                                      const SizedBox(height: 22),
                                      const Text(
                                        'رمز التحقق',
                                        style: TextStyle(
                                          color: NabadColors.darkText,
                                          fontSize: 27,
                                          fontWeight: FontWeight.w900,
                                          height: 1.15,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        widget.email == null
                                            ? 'أدخل رمز التحقق المرسل إليك.'
                                            : 'أدخل الرمز المرسل إلى ${widget.email}.',
                                        style: const TextStyle(
                                          color: NabadColors.mutedText,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                          height: 1.55,
                                        ),
                                      ),
                                      const SizedBox(height: 26),
                                      Row(
                                        textDirection: TextDirection.ltr,
                                        children: List.generate(
                                          6,
                                          (index) => Expanded(
                                            child: Padding(
                                              padding: EdgeInsets.only(left: index == 5 ? 0 : 7),
                                              child: _OtpDigitField(
                                                controller: _controllers[index],
                                                focusNode: _focusNodes[index],
                                                autofocus: index == 0,
                                                onChanged: (value) => _onCodeChanged(value, index),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 26),
                                      SizedBox(
                                        height: 56,
                                        child: ElevatedButton(
                                          onPressed: isVerifying ? null : _verifyCode,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: NabadColors.primary,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                          ),
                                          child: isVerifying
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2.5,
                                                  ),
                                                )
                                              : const Text(
                                                  'تأكيد الرمز',
                                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          const Text(
                                            'ألم تتلقى الرمز؟',
                                            style: TextStyle(
                                              color: NabadColors.mutedText,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: isResending ? null : _resendCode,
                                            style: TextButton.styleFrom(
                                              foregroundColor: NabadColors.primary,
                                              padding: const EdgeInsets.symmetric(horizontal: 6),
                                              textStyle: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            child: isResending
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  )
                                                : const Text('أرسل الرمز'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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

class _OtpDigitField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool autofocus;
  final ValueChanged<String> onChanged;

  const _OtpDigitField({
    required this.controller,
    required this.focusNode,
    required this.autofocus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      onChanged: onChanged,
      maxLength: 1,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(1),
      ],
      style: const TextStyle(
        color: NabadColors.deepTeal,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
      decoration: InputDecoration(
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: NabadColors.primary.withAlpha(22)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: NabadColors.primary, width: 1.5),
        ),
      ),
    );
  }
}