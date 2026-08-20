import 'package:nabad/Models/medicine_reminder_model.dart';

class MedicineReminderState {
  final List<MedicineReminderModel> reminders;
  final bool loading;
  final String? errorMessage;

  const MedicineReminderState({
    this.reminders = const [],
    this.loading = false,
    this.errorMessage,
  });

  MedicineReminderState copyWith({
    List<MedicineReminderModel>? reminders,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MedicineReminderState(
      reminders: reminders ?? this.reminders,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
