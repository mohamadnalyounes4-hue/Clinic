import 'package:nabad/Models/login_model.dart';
import 'package:nabad/Models/patient_model.dart';
import 'package:nabad/Models/signUp_model.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';
import 'package:nabad/core/Error/exceptions.dart';

class UserRepository {
  final ApiConsumer api;

  UserRepository({required this.api});

  // Register
  Future<SignUpModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await api.post(
        EndPoints.signUp,
        data: {
          ApiKey.firstName: firstName,
          ApiKey.lastName: lastName,
          ApiKey.email: email,
          ApiKey.phone: phone,
          ApiKey.password: password,
        },
      );
      return SignUpModel.fromJson(response);
    } on ServerExceptions {
      rethrow;
    }
  }

  // Login
  Future<LoginModel> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await api.post(
        EndPoints.login,
        data: {ApiKey.phone: phone, ApiKey.password: password},
      );
      return LoginModel.fromJson(response);
    } on ServerExceptions {
      rethrow;
    }
  }

  // Verify OTP
  Future<String> verifyOtp({
    required String email,
    required String code,
  }) async {
    try {
      final response = await api.post(
        EndPoints.verifyOtp,
        data: {ApiKey.email: email, 'code': code},
      );
      return response[ApiKey.message];
    } on ServerExceptions {
      rethrow;
    }
  }

  // Resend OTP
  Future<String> resendOtp({required String email}) async {
    try {
      final response = await api.post(
        EndPoints.resendOtp,
        data: {ApiKey.email: email},
      );
      return response[ApiKey.message];
    } on ServerExceptions {
      rethrow;
    }
  }

  // Complete Profile
  Future<void> completeProfile({
    required String gender,
    required String address,
    required String birthDate,
    required String bloodType,
  }) async {
    try {
      await api.post(
        EndPoints.completeProfile,
        data: {
          ApiKey.gender: gender,
          ApiKey.address: address,
          ApiKey.birthDate: birthDate,
          ApiKey.bloodType: bloodType,
        },
      );
    } on ServerExceptions {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await api.post(EndPoints.logout);
    } on ServerExceptions {
      rethrow;
    }
  }

  // getPatientProfile
  
  Future<PatientModel> getPatientProfile() async {
    try {
      final response = await api.get(EndPoints.profilePatient);
      final data = response['data'] ?? response;
      return PatientModel.fromJson(data);
    } on ServerExceptions {
      rethrow;
    }
  }
}