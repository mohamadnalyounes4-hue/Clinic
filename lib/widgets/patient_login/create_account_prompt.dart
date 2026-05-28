import 'package:flutter/material.dart';
import 'package:nabad/core/theme/nabad_colors.dart';

class CreateAccountPrompt extends StatelessWidget {
  final VoidCallback? onCreateAccount;

  const CreateAccountPrompt({super.key, this.onCreateAccount});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'في حال لم تمتلك حساب ؟ ',
          style: TextStyle(
            color: Color.fromARGB(255, 26, 98, 118),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextButton(
          onPressed: onCreateAccount,
          style: TextButton.styleFrom(
            foregroundColor: NabadColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            textStyle: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          child: Text('أنشئ حساب جديد'),
        ),
      ],
    );
  }
}
