import 'package:nabad/Models/department_model.dart';
import 'package:nabad/Models/doctor_model.dart';

// Department
abstract class DepartmentState {}

class DepartmentInitial extends DepartmentState {}

class DepartmentLoading extends DepartmentState {}

class DepartmentSuccess extends DepartmentState {
  final List<DepartmentModel> departments;
  DepartmentSuccess({required this.departments});
}

class DepartmentError extends DepartmentState {
  final String message;
  DepartmentError({required this.message});
}

// Doctor
abstract class DoctorState {}

class DoctorInitial extends DoctorState {}

class DoctorLoading extends DoctorState {}

class DoctorSuccess extends DoctorState {
  final List<DoctorModel> doctors;
  DoctorSuccess({required this.doctors});
}

class DoctorError extends DoctorState {
  final String message;
  DoctorError({required this.message});
}