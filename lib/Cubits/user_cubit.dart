import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/user_state.dart';
import 'package:nabad/Repositories/user_repository.dart';
import 'package:nabad/core/Api/end_points.dart';
import 'package:nabad/core/Cache/cache_helper.dart';
import 'package:nabad/core/Error/exceptions.dart';

class UserCubit extends Cubit<UserState> {
  final UserRepository userRepository;

  UserCubit({required this.userRepository}) : super(UserInitial());

  // Register
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    emit(RegisterLoading());
    try {
      final result = await userRepository.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
      );
      await CacheHelper.saveData(key: ApiKey.email, value: result.user.email);
      emit(RegisterSuccess());
    } on ServerExceptions catch (e) {
      emit(RegisterError(message: e.errModel.errorMessage));
    }
  }

  // Login
  Future<void> login({
    required String phone,
    required String password,
  }) async {
    emit(LoginLoading());
    try {
      final result = await userRepository.login(
        phone: phone,
        password: password,
      );
      await CacheHelper.saveData(key: ApiKey.token, value: result.token);
      await CacheHelper.saveData(key: ApiKey.id, value: result.user.id);
      await CacheHelper.saveData(key: ApiKey.role, value: result.user.role);
      emit(LoginSuccess());
    } on ServerExceptions catch (e) {
      emit(LoginError(message: e.errModel.errorMessage));
    }
  }

  // Verify OTP
  Future<void> verifyOtp({
    required String email,
    required String code,
  }) async {
    emit(VerifyOtpLoading());
    try {
      await userRepository.verifyOtp(email: email, code: code);
      emit(VerifyOtpSuccess());
    } on ServerExceptions catch (e) {
      emit(VerifyOtpError(message: e.errModel.errorMessage));
    }
  }

  // Resend OTP
  Future<void> resendOtp({required String email}) async {
    emit(ResendOtpLoading());
    try {
      await userRepository.resendOtp(email: email);
      emit(ResendOtpSuccess());
    } on ServerExceptions catch (e) {
      emit(ResendOtpError(message: e.errModel.errorMessage));
    }
  }

  // Complete Profile
  Future<void> completeProfile({
    required String gender,
    required String address,
    required String birthDate,
    required String bloodType,
  }) async {
    emit(CompleteProfileLoading());
    try {
      await userRepository.completeProfile(
        gender: gender,
        address: address,
        birthDate: birthDate,
        bloodType: bloodType,
      );
      emit(CompleteProfileSuccess());
    } on ServerExceptions catch (e) {
      emit(CompleteProfileError(message: e.errModel.errorMessage));
    }
  }

  // Logout
  Future<void> logout() async {
    emit(LogoutLoading());
    try {
      await userRepository.logout();
      await CacheHelper.clearData();
      emit(LogoutSuccess());
    } on ServerExceptions catch (e) {
      emit(LogoutError(message: e.errModel.errorMessage));
    }
  }
}