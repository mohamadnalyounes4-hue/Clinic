import 'package:flutter/material.dart';
import 'package:nabad/core/router/app_router.dart';
import 'package:nabad/core/theme/nabad_colors.dart';
import 'package:nabad/core/localization/app_localizations.dart';
import 'package:nabad/widgets/account_type/account_role.dart';
import 'package:nabad/widgets/account_type/benefit_strip.dart';
import 'package:nabad/widgets/account_type/glass_slide_button.dart';
import 'package:nabad/widgets/account_type/role_preview.dart';
import 'package:nabad/widgets/account_type/role_selector.dart';
import 'package:nabad/widgets/soft_ring.dart';

class AccountTypeScreen extends StatefulWidget {
  const AccountTypeScreen({super.key});

  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  AccountRole _selectedRole = AccountRole.patient;

  AccountRoleContent _content(BuildContext context) =>
      _selectedRole == AccountRole.patient
      ? AccountRoleContent(
          title: context.tr('مريض'),
          headline: context.tr('مساحتك الصحية الشخصية'),
          subtitle: context.tr(
            'احجز موعدك، تابع ملفك الطبي، وراجع نتائجك من مكان واحد.',
          ),
          action: context.tr('المتابعة كمريض'),
          image: 'assets/images/Female.jpg',
          routeName: AppRoutes.patientLogin,
          icon: Icons.person_rounded,
        )
      : AccountRoleContent(
          title: context.tr('طبيب'),
          headline: context.tr('إدارة العيادة بذكاء'),
          subtitle: context.tr(
            'نظم المواعيد، تابع المرضى، وادخل إلى الملفات الطبية بسرعة.',
          ),
          action: context.tr('المتابعة كطبيب'),
          image: 'assets/images/4.jpg',
          routeName: AppRoutes.doctorLogin,
          icon: Icons.medical_services_rounded,
        );

  void _continue() {
    Navigator.pushNamed(context, _content(context).routeName);
  }

  @override
  Widget build(BuildContext context) {
    final content = _content(context);
    return Directionality(
      textDirection: context.l10n.isArabic
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: NabadColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned(top: 86, right: -58, child: SoftRing(size: 190)),
              Positioned(
                bottom: 120,
                left: -72,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.08,
                    child: Image.asset(
                      'assets/images/logoIcon.png',
                      width: 210,
                      height: 210,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 2),
                    Text(
                      context.tr('حدد نوع حسابك'),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 33, 126, 143),
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(
                        'اختر المسار المناسب حتى نعرض لك تجربة مصممة لدورك داخل مركز العيادات.',
                      ),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 33, 126, 143),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        height: 1.55,
                      ),
                    ),
                    const Spacer(flex: 2),
                    RolePreview(content: content),
                    const Spacer(flex: 2),
                    Row(
                      children: [
                        Expanded(
                          child: RoleSelector(
                            title: context.tr('مريض'),
                            icon: Icons.person_rounded,
                            isSelected: _selectedRole == AccountRole.patient,
                            onTap: () => setState(
                              () => _selectedRole = AccountRole.patient,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: RoleSelector(
                            title: context.tr('طبيب'),
                            icon: Icons.medical_services_rounded,
                            isSelected: _selectedRole == AccountRole.doctor,
                            onTap: () => setState(
                              () => _selectedRole = AccountRole.doctor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    BenefitStrip(role: _selectedRole),
                    const Spacer(flex: 2),
                    GlassSlideButton(
                      key: ValueKey(content.action),
                      label: context.tr(
                        _selectedRole == AccountRole.patient
                            ? 'اسحب للمتابعة كمريض'
                            : 'اسحب للمتابعة كطبيب',
                      ),
                      onComplete: _continue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
