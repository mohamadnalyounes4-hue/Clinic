import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/cubits/medicine_reminder_cubit.dart';
import 'package:nabad/Cubits/states/medicine_reminder_state.dart';
import 'package:nabad/Models/medicine_reminder_model.dart';
import 'package:nabad/core/theme/nabad_colors.dart';

class MedicineRemindersScreen extends StatefulWidget {
  const MedicineRemindersScreen({super.key});

  @override
  State<MedicineRemindersScreen> createState() =>
      _MedicineRemindersScreenState();
}

class _MedicineRemindersScreenState extends State<MedicineRemindersScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MedicineReminderCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: NabadColors.background,
        appBar: AppBar(
          title: const Text(
            'تذكيرات الأدوية',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: NabadColors.deepTeal,
          surfaceTintColor: Colors.transparent,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openReminderForm(context),
          backgroundColor: NabadColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'تذكير جديد',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: BlocConsumer<MedicineReminderCubit, MedicineReminderState>(
          listenWhen: (previous, current) =>
              previous.errorMessage != current.errorMessage &&
              current.errorMessage != null,
          listener: (context, state) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            context.read<MedicineReminderCubit>().clearError();
          },
          builder: (context, state) {
            if (state.reminders.isEmpty) {
              return _EmptyState(onAdd: () => _openReminderForm(context));
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
              itemCount: state.reminders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final reminder = state.reminders[index];
                return _ReminderCard(
                  reminder: reminder,
                  onToggle: (value) => context
                      .read<MedicineReminderCubit>()
                      .toggle(reminder, value),
                  onEdit: () => _openReminderForm(context, reminder: reminder),
                  onDelete: () => _confirmDelete(context, reminder),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _openReminderForm(
    BuildContext context, {
    MedicineReminderModel? reminder,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<MedicineReminderCubit>(),
        child: _ReminderForm(reminder: reminder),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    MedicineReminderModel reminder,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف التذكير؟'),
        content: Text('لن يصلك تنبيه ${reminder.medicineName} بعد الحذف.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<MedicineReminderCubit>().delete(reminder);
    }
  }
}

class _ReminderCard extends StatelessWidget {
  final MedicineReminderModel reminder;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: reminder.enabled ? 1 : 0.58,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: NabadColors.divider),
          boxShadow: [
            BoxShadow(
              color: NabadColors.primary.withAlpha(12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: NabadColors.softTeal,
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(
                Icons.medication_outlined,
                color: NabadColors.primary,
                size: 27,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: onEdit,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.medicineName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: NabadColors.darkText,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (reminder.dosage.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        reminder.dosage,
                        style: const TextStyle(
                          color: NabadColors.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: NabadColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${reminder.formattedTime} • يومياً',
                          style: const TextStyle(
                            color: NabadColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                Switch.adaptive(value: reminder.enabled, onChanged: onToggle),
                PopupMenuButton<String>(
                  tooltip: 'خيارات',
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('تعديل')),
                    PopupMenuItem(value: 'delete', child: Text('حذف')),
                  ],
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: NabadColors.mutedText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderForm extends StatefulWidget {
  final MedicineReminderModel? reminder;
  const _ReminderForm({this.reminder});

  @override
  State<_ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<_ReminderForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late TimeOfDay _time;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    _nameController = TextEditingController(text: reminder?.medicineName ?? '');
    _dosageController = TextEditingController(text: reminder?.dosage ?? '');
    _time = reminder == null
        ? TimeOfDay.now()
        : TimeOfDay(hour: reminder.hour, minute: reminder.minute);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: _SheetHandle()),
                  const SizedBox(height: 18),
                  Text(
                    widget.reminder == null
                        ? 'إضافة تذكير دواء'
                        : 'تعديل التذكير',
                    style: const TextStyle(
                      color: NabadColors.darkText,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      label: 'اسم الدواء',
                      icon: Icons.medication_outlined,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'أدخل اسم الدواء'
                        : null,
                  ),
                  const SizedBox(height: 13),
                  TextFormField(
                    controller: _dosageController,
                    decoration: _inputDecoration(
                      label: 'الجرعة (اختياري)',
                      icon: Icons.medical_information_outlined,
                      hint: 'مثال: حبة واحدة بعد الطعام',
                    ),
                  ),
                  const SizedBox(height: 13),
                  InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(16),
                    child: InputDecorator(
                      decoration: _inputDecoration(
                        label: 'وقت التذكير',
                        icon: Icons.schedule_rounded,
                      ),
                      child: Text(
                        _time.format(context),
                        style: const TextStyle(
                          color: NabadColors.darkText,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(
                        Icons.repeat_rounded,
                        size: 17,
                        color: NabadColors.mutedText,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'سيتكرر التذكير يومياً في الوقت المحدد',
                        style: TextStyle(
                          color: NabadColors.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: NabadColors.primary,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.notifications_active_outlined),
                      label: Text(
                        widget.reminder == null ? 'حفظ التذكير' : 'حفظ التعديل',
                        style: const TextStyle(fontWeight: FontWeight.w900),
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

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final existing = widget.reminder;
    final reminder = MedicineReminderModel(
      id: existing?.id ?? (DateTime.now().millisecondsSinceEpoch % 2147483647),
      medicineName: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      hour: _time.hour,
      minute: _time.minute,
      enabled: existing?.enabled ?? true,
    );
    final saved = await context.read<MedicineReminderCubit>().saveReminder(
      reminder,
    );
    if (mounted) {
      setState(() => _saving = false);
      if (saved) Navigator.pop(context);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: NabadColors.primary),
      filled: true,
      fillColor: NabadColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: NabadColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: NabadColors.primary, width: 1.5),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 5,
      decoration: BoxDecoration(
        color: NabadColors.divider,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: NabadColors.softTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medication_outlined,
                size: 44,
                color: NabadColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'لا توجد تذكيرات أدوية',
              style: TextStyle(
                color: NabadColors.darkText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'أضف دواءً ووقت تناوله ليصلك تنبيه يومي على جهازك.',
              textAlign: TextAlign.center,
              style: TextStyle(color: NabadColors.mutedText, height: 1.5),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة أول تذكير'),
            ),
          ],
        ),
      ),
    );
  }
}
