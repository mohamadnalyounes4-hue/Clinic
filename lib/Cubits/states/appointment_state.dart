
import 'package:nabad/Models/appointment_model.dart';

abstract class AppointmentState {}

class AppointmentInitial extends AppointmentState {}

class AppointmentLoading extends AppointmentState {}

class AppointmentSuccess extends AppointmentState {
  final List<AppointmentModel> appointments;
  AppointmentSuccess({required this.appointments});
}

class AppointmentError extends AppointmentState {
  final String message;
  AppointmentError({required this.message});
}
