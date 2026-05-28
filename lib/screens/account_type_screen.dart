import 'package:flutter/material.dart';
import 'package:nabad/core/router/app_router.dart';
import 'package:nabad/core/theme/nabad_colors.dart';
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

  AccountRoleContent get _content => _selectedRole == AccountRole.patient
      ? const AccountRoleContent(
          title: 'مريض',
          headline: 'مساحتك الصحية الشخصية',
          subtitle: 'احجز موعدك، تابع ملفك الطبي، وراجع نتائجك من مكان واحد.',
          action: 'المتابعة كمريض',
          image: 'assets/images/Female.jpg',
          routeName: AppRoutes.patientLogin,
          icon: Icons.person_rounded,
        )
      : const AccountRoleContent(
          title: 'طبيب',
          headline: 'إدارة العيادة بذكاء',
          subtitle:
              'نظم المواعيد، تابع المرضى، وادخل إلى الملفات الطبية بسرعة.',
          action: 'المتابعة كطبيب',
          image: 'assets/images/4.jpg',
          routeName: AppRoutes.doctorLogin,
          icon: Icons.medical_services_rounded,
        );

  void _continue() {
    Navigator.pushNamed(context, _content.routeName);
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
                    const Text(
                      'حدد نوع حسابك',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Color.fromARGB(255, 33, 126, 143),
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'اختر المسار المناسب حتى نعرض لك تجربة مصممة لدورك داخل مركز العيادات.',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Color.fromARGB(255, 33, 126, 143),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        height: 1.55,
                      ),
                    ),
                    const Spacer(flex: 2),
                    RolePreview(content: _content),
                    const Spacer(flex: 2),
                    Row(
                      children: [
                        Expanded(
                          child: RoleSelector(
                            title: 'مريض',
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
                            title: 'طبيب',
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
                      key: ValueKey(_content.action),
                      label: _content.action.replaceFirst(
                        'المتابعة',
                        'اسحب للمتابعة',
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
