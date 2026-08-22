import 'package:nabad/Models/doctor_earnings_model.dart';

sealed class DoctorEarningsState {
  const DoctorEarningsState();
}

class DoctorEarningsInitial extends DoctorEarningsState {
  const DoctorEarningsInitial();
}

class DoctorEarningsLoading extends DoctorEarningsState {
  const DoctorEarningsLoading();
}

class DoctorEarningsSuccess extends DoctorEarningsState {
  final DoctorEarningsModel earnings;

  const DoctorEarningsSuccess(this.earnings);
}

class DoctorEarningsError extends DoctorEarningsState {
  final String message;

  const DoctorEarningsError(this.message);
}
