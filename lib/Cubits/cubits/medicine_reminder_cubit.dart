import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/states/medicine_reminder_state.dart';
import 'package:nabad/Models/medicine_reminder_model.dart';
import 'package:nabad/core/notifications/medicine_reminder_service.dart';

class MedicineReminderCubit extends Cubit<MedicineReminderState> {
  final MedicineReminderService service;

  MedicineReminderCubit({required this.service})
    : super(const MedicineReminderState());

  void load() {
    final reminders = [...service.load()]
      ..sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
      );
    emit(state.copyWith(reminders: reminders, clearError: true));
  }

  Future<bool> saveReminder(MedicineReminderModel reminder) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      if (reminder.enabled && !await service.requestPermissions()) {
        emit(
          state.copyWith(
            loading: false,
            errorMessage: 'يجب السماح بالإشعارات لتفعيل تذكير الدواء.',
          ),
        );
        return false;
      }
      final reminders = [...state.reminders];
      final index = reminders.indexWhere((item) => item.id == reminder.id);
      if (index < 0) {
        reminders.add(reminder);
      } else {
        reminders[index] = reminder;
      }
      reminders.sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
      );
      await service.save(reminders);
      await service.schedule(reminder);
      emit(
        state.copyWith(reminders: reminders, loading: false, clearError: true),
      );
      return true;
    } catch (_) {
      emit(
        state.copyWith(
          loading: false,
          errorMessage: 'تعذر حفظ التذكير. حاول مجدداً.',
        ),
      );
      return false;
    }
  }

  Future<void> toggle(MedicineReminderModel reminder, bool enabled) async {
    await saveReminder(reminder.copyWith(enabled: enabled));
  }

  Future<void> delete(MedicineReminderModel reminder) async {
    final reminders = state.reminders
        .where((item) => item.id != reminder.id)
        .toList();
    await service.cancel(reminder.id);
    await service.save(reminders);
    emit(state.copyWith(reminders: reminders, clearError: true));
  }

  void clearError() => emit(state.copyWith(clearError: true));
}
