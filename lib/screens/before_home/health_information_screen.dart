import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/user_cubit.dart';
import 'package:nabad/Cubits/user_state.dart';
import 'package:nabad/core/theme/nabad_colors.dart';
import 'package:nabad/screens/HomePage_patient/homepage_p.dart';
import 'package:nabad/widgets/soft_ring.dart';

class HealthInformationScreen extends StatefulWidget {
  const HealthInformationScreen({super.key});

  @override
  State<HealthInformationScreen> createState() => _HealthInformationScreenState();
}

class _HealthInformationScreenState extends State<HealthInformationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _chronicDiseaseController = TextEditingController();
  final TextEditingController _allergyController = TextEditingController();

  String? _bloodType;
  String? _gender;
  bool? _hasChronicDisease;
  bool? _hasAllergy;

  final List<String> _bloodTypes = const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _genders = const ['male', 'female'];
  final Map<String, String> _genderLabels = const {'male': 'ذكر', 'female': 'أنثى'};

  @override
  void dispose() {
    _birthDateController.dispose();
    _addressController.dispose();
    _chronicDiseaseController.dispose();
    _allergyController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (pickedDate == null) return;
    setState(() {
      _birthDateController.text =
          '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
    });
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;

    if (_gender == null) {
      _showSnackBar('حدد الجنس');
      return;
    }
    if (_bloodType == null) {
      _showSnackBar('حدد زمرة الدم');
      return;
    }
    if (_hasChronicDisease == null) {
      _showSnackBar('حدد هل لديك مرض مزمن');
      return;
    }
    if (_hasAllergy == null) {
      _showSnackBar('حدد هل لديك حساسية');
      return;
    }

    context.read<UserCubit>().completeProfile(
          gender: _gender!,
          address: _addressController.text.trim(),
          birthDate: _birthDateController.text,
          bloodType: _bloodType!,
        );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _requiredValidator(String? value, String label) {
    if ((value ?? '').trim().isEmpty) return '$label مطلوب';
    return null;
  }

  String? _conditionalRequiredValidator(String? value, {required bool isRequired, required String label}) {
    if (isRequired && (value ?? '').trim().isEmpty) return '$label مطلوب';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserCubit, UserState>(
      listener: (context, state) {
        if (state is CompleteProfileSuccess) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const PatientHomePage()),
            (route) => false,
          );
        } else if (state is CompleteProfileError) {
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
                const Positioned(top: 70, right: -76, child: SoftRing(size: 230)),
                Positioned(
                  left: -46,
                  bottom: 120,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.055,
                      child: Image.asset('assets/images/logoIcon.png', width: 210, height: 210, fit: BoxFit.contain),
                    ),
                  ),
                ),
                BlocBuilder<UserCubit, UserState>(
                  builder: (context, state) {
                    final isLoading = state is CompleteProfileLoading;
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _HealthHero(onBack: () => Navigator.maybePop(context)),
                                const SizedBox(height: 18),
                                _ProgressHint(
                                  hasBirthDate: _birthDateController.text.isNotEmpty,
                                  hasBloodType: _bloodType != null,
                                  hasGender: _gender != null,
                                  hasAddress: _addressController.text.isNotEmpty,
                                ),
                                const SizedBox(height: 18),
                                _AnimatedEntrance(
                                  delay: const Duration(milliseconds: 80),
                                  child: _HealthFormCard(
                                    formKey: _formKey,
                                    birthDateController: _birthDateController,
                                    addressController: _addressController,
                                    chronicDiseaseController: _chronicDiseaseController,
                                    allergyController: _allergyController,
                                    bloodTypes: _bloodTypes,
                                    bloodType: _bloodType,
                                    genders: _genders,
                                    genderLabels: _genderLabels,
                                    gender: _gender,
                                    hasChronicDisease: _hasChronicDisease,
                                    hasAllergy: _hasAllergy,
                                    isLoading: isLoading,
                                    onBirthDateTap: _pickBirthDate,
                                    onBloodTypeChanged: (value) => setState(() => _bloodType = value),
                                    onGenderChanged: (value) => setState(() => _gender = value),
                                    onChronicChanged: (value) {
                                      setState(() {
                                        _hasChronicDisease = value;
                                        if (value == false) _chronicDiseaseController.clear();
                                      });
                                    },
                                    onAllergyChanged: (value) {
                                      setState(() {
                                        _hasAllergy = value;
                                        if (value == false) _allergyController.clear();
                                      });
                                    },
                                    requiredValidator: _requiredValidator,
                                    conditionalRequiredValidator: _conditionalRequiredValidator,
                                    onContinue: isLoading ? null : _continue,
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

// ─── Hero ────────────────────────────────────────────────────────────────────

class _HealthHero extends StatelessWidget {
  final VoidCallback onBack;
  const _HealthHero({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return _AnimatedEntrance(
      child: Container(
        height: 218,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: NabadColors.primary.withAlpha(30), blurRadius: 30, offset: const Offset(0, 16))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/11.jpg', fit: BoxFit.cover, alignment: Alignment.centerRight),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [NabadColors.primary.withAlpha(225), NabadColors.primary.withAlpha(128), Colors.transparent],
                ),
              ),
            ),
            Positioned(
              left: 14,
              top: 14,
              child: IconButton.filled(
                onPressed: onBack,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withAlpha(225),
                  foregroundColor: NabadColors.primary,
                  fixedSize: const Size(44, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
            Positioned(
              right: 22,
              left: 96,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: Colors.white.withAlpha(220), borderRadius: BorderRadius.circular(999)),
                    child: const Text('الملف الطبي', style: TextStyle(color: NabadColors.primary, fontSize: 12.5, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Your health information',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.1)),
                  const SizedBox(height: 8),
                  Text('أكمل معلوماتك الصحية حتى يتم تجهيز ملفك الطبي بدقة.',
                      style: TextStyle(color: Colors.white.withAlpha(225), fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.45)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Progress ─────────────────────────────────────────────────────────────────

class _ProgressHint extends StatelessWidget {
  final bool hasBirthDate;
  final bool hasBloodType;
  final bool hasGender;
  final bool hasAddress;

  const _ProgressHint({
    required this.hasBirthDate,
    required this.hasBloodType,
    required this.hasGender,
    required this.hasAddress,
  });

  int get _doneCount => [hasBirthDate, hasBloodType, hasGender, hasAddress].where((d) => d).length;

  @override
  Widget build(BuildContext context) {
    return _AnimatedEntrance(
      delay: const Duration(milliseconds: 40),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(230),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: NabadColors.primary.withAlpha(20)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: NabadColors.primary.withAlpha(22), borderRadius: BorderRadius.circular(17)),
              child: const Icon(Icons.fact_check_rounded, color: NabadColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('اكتمل $_doneCount من 4',
                      style: const TextStyle(color: NabadColors.deepTeal, fontSize: 14, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: _doneCount / 4,
                      minHeight: 7,
                      backgroundColor: NabadColors.primary.withAlpha(18),
                      valueColor: const AlwaysStoppedAnimation<Color>(NabadColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Form Card ────────────────────────────────────────────────────────────────

class _HealthFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController birthDateController;
  final TextEditingController addressController;
  final TextEditingController chronicDiseaseController;
  final TextEditingController allergyController;
  final List<String> bloodTypes;
  final String? bloodType;
  final List<String> genders;
  final Map<String, String> genderLabels;
  final String? gender;
  final bool? hasChronicDisease;
  final bool? hasAllergy;
  final bool isLoading;
  final VoidCallback onBirthDateTap;
  final ValueChanged<String?> onBloodTypeChanged;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<bool> onChronicChanged;
  final ValueChanged<bool> onAllergyChanged;
  final String? Function(String?, String) requiredValidator;
  final String? Function(String?, {required bool isRequired, required String label}) conditionalRequiredValidator;
  final VoidCallback? onContinue;

  const _HealthFormCard({
    required this.formKey,
    required this.birthDateController,
    required this.addressController,
    required this.chronicDiseaseController,
    required this.allergyController,
    required this.bloodTypes,
    required this.bloodType,
    required this.genders,
    required this.genderLabels,
    required this.gender,
    required this.hasChronicDisease,
    required this.hasAllergy,
    required this.isLoading,
    required this.onBirthDateTap,
    required this.onBloodTypeChanged,
    required this.onGenderChanged,
    required this.onChronicChanged,
    required this.onAllergyChanged,
    required this.requiredValidator,
    required this.conditionalRequiredValidator,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(240),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withAlpha(230)),
        boxShadow: [BoxShadow(color: NabadColors.primary.withAlpha(18), blurRadius: 28, offset: const Offset(0, 16))],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle(icon: Icons.person_search_rounded, title: 'المعلومات الأساسية'),
            const SizedBox(height: 16),

            // Birth Date
            _HealthTextField(
              controller: birthDateController,
              label: 'تاريخ الميلاد',
              hintText: 'اختر تاريخ الميلاد',
              icon: Icons.calendar_month_rounded,
              readOnly: true,
              onTap: onBirthDateTap,
              validator: (value) => requiredValidator(value, 'تاريخ الميلاد'),
            ),
            const SizedBox(height: 16),

            // Gender
            const _FieldLabel(label: 'الجنس'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: gender,
              isExpanded: true,
              decoration: _inputDecoration(hintText: 'اختر الجنس', icon: Icons.wc_rounded),
              borderRadius: BorderRadius.circular(18),
              items: genders.map((g) {
                return DropdownMenuItem<String>(
                  value: g,
                  child: Text(genderLabels[g]!, style: const TextStyle(color: NabadColors.deepTeal, fontWeight: FontWeight.w800)),
                );
              }).toList(),
              onChanged: onGenderChanged,
              validator: (value) => value == null ? 'الجنس مطلوب' : null,
            ),
            const SizedBox(height: 16),

            // Address
            _HealthTextField(
              controller: addressController,
              label: 'العنوان',
              hintText: 'مثال: دمشق، سوريا',
              icon: Icons.location_on_rounded,
              validator: (value) => requiredValidator(value, 'العنوان'),
            ),
            const SizedBox(height: 16),

            // Blood Type
            const _FieldLabel(label: 'زمرة الدم'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: bloodType,
              isExpanded: true,
              decoration: _inputDecoration(hintText: 'اختر زمرة الدم', icon: Icons.bloodtype_rounded),
              borderRadius: BorderRadius.circular(18),
              items: bloodTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type, textDirection: TextDirection.ltr,
                      style: const TextStyle(color: NabadColors.deepTeal, fontWeight: FontWeight.w800)),
                );
              }).toList(),
              onChanged: onBloodTypeChanged,
              validator: (value) => value == null ? 'زمرة الدم مطلوبة' : null,
            ),
            const SizedBox(height: 22),

            const _SectionTitle(icon: Icons.health_and_safety_rounded, title: 'الحالة الصحية'),
            const SizedBox(height: 14),

            _AnimatedHealthQuestion(
              question: 'هل لديك مرض مزمن؟',
              description: 'مثل السكري، الضغط، أمراض القلب أو الربو.',
              value: hasChronicDisease,
              yesIcon: Icons.medical_information_rounded,
              onChanged: onChronicChanged,
            ),
            _ConditionalAnimatedField(
              isVisible: hasChronicDisease == true,
              child: _HealthTextField(
                controller: chronicDiseaseController,
                label: 'وصف المرض المزمن',
                hintText: 'اكتب وصف المرض المزمن',
                icon: Icons.edit_note_rounded,
                maxLines: 3,
                validator: (value) => conditionalRequiredValidator(value, isRequired: hasChronicDisease == true, label: 'وصف المرض المزمن'),
              ),
            ),
            const SizedBox(height: 16),

            _AnimatedHealthQuestion(
              question: 'هل لديك حساسية؟',
              description: 'مثل حساسية الأدوية، الطعام أو المواد الطبية.',
              value: hasAllergy,
              yesIcon: Icons.warning_amber_rounded,
              onChanged: onAllergyChanged,
            ),
            _ConditionalAnimatedField(
              isVisible: hasAllergy == true,
              child: _HealthTextField(
                controller: allergyController,
                label: 'وصف الحساسية',
                hintText: 'اكتب نوع الحساسية',
                icon: Icons.edit_note_rounded,
                maxLines: 3,
                validator: (value) => conditionalRequiredValidator(value, isRequired: hasAllergy == true, label: 'وصف الحساسية'),
              ),
            ),
            const SizedBox(height: 26),

            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NabadColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('متابعة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: NabadColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: NabadColors.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(color: NabadColors.darkText, fontSize: 17, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _AnimatedHealthQuestion extends StatelessWidget {
  final String question;
  final String description;
  final bool? value;
  final IconData yesIcon;
  final ValueChanged<bool> onChanged;

  const _AnimatedHealthQuestion({
    required this.question,
    required this.description,
    required this.value,
    required this.yesIcon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FBFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: value == null ? NabadColors.primary.withAlpha(18) : NabadColors.primary.withAlpha(52)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(question, style: const TextStyle(color: NabadColors.deepTeal, fontSize: 15, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 5),
                    Text(description,
                        style: const TextStyle(color: NabadColors.mutedText, fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  value == true ? yesIcon : value == false ? Icons.check_circle_rounded : Icons.help_outline_rounded,
                  key: ValueKey(value),
                  color: value == null ? NabadColors.mutedText : NabadColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(child: _ChoiceTile(label: 'نعم', isSelected: value == true, onTap: () => onChanged(true))),
              const SizedBox(width: 10),
              Expanded(child: _ChoiceTile(label: 'لا', isSelected: value == false, onTap: () => onChanged(false))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChoiceTile({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 190),
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? NabadColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? NabadColors.primary : NabadColors.primary.withAlpha(28)),
          boxShadow: isSelected
              ? [BoxShadow(color: NabadColors.primary.withAlpha(28), blurRadius: 18, offset: const Offset(0, 8))]
              : null,
        ),
        child: Text(label,
            style: TextStyle(color: isSelected ? Colors.white : NabadColors.deepTeal, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _ConditionalAnimatedField extends StatelessWidget {
  final bool isVisible;
  final Widget child;

  const _ConditionalAnimatedField({required this.isVisible, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return SizeTransition(sizeFactor: animation, child: FadeTransition(opacity: animation, child: child));
      },
      child: isVisible
          ? Padding(key: const ValueKey('visible-field'), padding: const EdgeInsets.only(top: 12), child: child)
          : const SizedBox.shrink(key: ValueKey('hidden-field')),
    );
  }
}

class _HealthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final bool readOnly;
  final int maxLines;
  final VoidCallback? onTap;
  final FormFieldValidator<String> validator;

  const _HealthTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.validator,
    this.readOnly = false,
    this.maxLines = 1,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(label: label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          decoration: _inputDecoration(hintText: hintText, icon: icon),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: const TextStyle(color: NabadColors.deepTeal, fontSize: 13.5, fontWeight: FontWeight.w900));
  }
}

class _AnimatedEntrance extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedEntrance({required this.child, this.delay = Duration.zero});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + delay.inMilliseconds),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final double delayedValue = delay == Duration.zero
            ? value
            : ((value * (520 + delay.inMilliseconds) - delay.inMilliseconds) / 520).clamp(0.0, 1.0);
        return Opacity(
          opacity: delayedValue,
          child: Transform.translate(offset: Offset(0, 18 * (1 - delayedValue)), child: child),
        );
      },
      child: child,
    );
  }
}

InputDecoration _inputDecoration({required String hintText, required IconData icon}) {
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: const Color(0xFFF4FBFC),
    prefixIcon: Icon(icon, color: NabadColors.primary),
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