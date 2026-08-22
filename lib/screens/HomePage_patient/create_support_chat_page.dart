import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/cubits/support_cubit.dart';
import 'package:nabad/Cubits/states/support_state.dart';
import 'package:nabad/core/localization/app_localizations.dart';
import 'package:nabad/core/router/app_router.dart';
import 'package:nabad/core/theme/nabad_colors.dart';

class CreateSupportChatPage extends StatefulWidget {
  const CreateSupportChatPage({super.key});

  @override
  State<CreateSupportChatPage> createState() => _CreateSupportChatPageState();
}

class _CreateSupportChatPageState extends State<CreateSupportChatPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _priority = 'normal';

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ticket = await context.read<SupportCubit>().createTicket(
      subject: _subjectController.text,
      description: _descriptionController.text,
      priority: _priority,
    );
    if (ticket != null && mounted) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.supportChat,
        arguments: ticket.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: context.l10n.isArabic
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: BlocListener<SupportCubit, SupportState>(
        listenWhen: (previous, current) =>
            previous.actionError != current.actionError,
        listener: (context, state) {
          if (state.actionStatusCode == 401) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.welcome,
              (_) => false,
            );
            return;
          }
          if (state.actionError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr(state.actionError!))),
            );
            context.read<SupportCubit>().clearActionError();
          }
        },
        child: Scaffold(
          backgroundColor: NabadColors.background,
          appBar: AppBar(
            title: Text(
              context.tr('محادثة دعم جديدة'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: NabadColors.deepTeal,
            surfaceTintColor: Colors.transparent,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('كيف يمكننا مساعدتك؟'),
                          style: const TextStyle(
                            color: NabadColors.darkText,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr(
                            'اكتب تفاصيل واضحة ليتمكن فريق الدعم من مساعدتك بسرعة.',
                          ),
                          style: const TextStyle(
                            color: NabadColors.mutedText,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _subjectController,
                          maxLength: 160,
                          decoration: _inputDecoration(
                            context.tr('عنوان المحادثة'),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? context.tr('يرجى كتابة عنوان المحادثة.')
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          minLines: 5,
                          maxLines: 9,
                          maxLength: 3000,
                          decoration: _inputDecoration(
                            context.tr('شرح المشكلة'),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? context.tr('يرجى شرح المشكلة.')
                              : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _priority,
                          decoration: _inputDecoration(
                            context.tr('أولوية الشكوى'),
                          ),
                          items: const ['low', 'normal', 'high', 'urgent']
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(
                                    context.tr(_createPriorityLabel(value)),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _priority = value ?? 'normal'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  BlocBuilder<SupportCubit, SupportState>(
                    buildWhen: (previous, current) =>
                        previous.creating != current.creating,
                    builder: (context, state) => SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: state.creating ? null : _submit,
                        icon: state.creating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.forum_outlined),
                        label: Text(
                          context.tr(
                            state.creating
                                ? 'جارٍ الإنشاء...'
                                : 'إنشاء محادثة دعم',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFFF6FAFB),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: NabadColors.divider),
    ),
  );
}

String _createPriorityLabel(String value) => switch (value) {
  'low' => 'منخفضة',
  'high' => 'عالية',
  'urgent' => 'عاجلة',
  _ => 'عادية',
};
