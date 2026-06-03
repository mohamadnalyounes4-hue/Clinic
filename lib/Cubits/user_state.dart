abstract class UserState {}

class UserInitial extends UserState {}

// Register
class RegisterLoading extends UserState {}
class RegisterSuccess extends UserState {}
class RegisterError extends UserState {
  final String message;
  RegisterError({required this.message});
}

// Login
class LoginLoading extends UserState {}
class LoginSuccessPatient extends UserState {}
class LoginSuccessDoctor extends UserState {}
class LoginError extends UserState {
  final String message;
  LoginError({required this.message});
}

// Verify OTP
class VerifyOtpLoading extends UserState {}
class VerifyOtpSuccess extends UserState {}
class VerifyOtpError extends UserState {
  final String message;
  VerifyOtpError({required this.message});
}

// Resend OTP
class ResendOtpLoading extends UserState {}
class ResendOtpSuccess extends UserState {}
class ResendOtpError extends UserState {
  final String message;
  ResendOtpError({required this.message});
}

// Complete Profile
class CompleteProfileLoading extends UserState {}
class CompleteProfileSuccess extends UserState {}
class CompleteProfileError extends UserState {
  final String message;
  CompleteProfileError({required this.message});
}

// Logout
class LogoutLoading extends UserState {}
class LogoutSuccess extends UserState {}
class LogoutError extends UserState {
  final String message;
  LogoutError({required this.message});
}