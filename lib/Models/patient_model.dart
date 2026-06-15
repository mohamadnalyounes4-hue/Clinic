import 'package:nabad/Models/user_model.dart';
import 'package:nabad/core/Api/end_points.dart';

class PatientModel {
  final int id;
  final int userId;
  final String? gender;
  final String? birthDate;
  final String? address;
  final String? bloodType;
  final UserModel user;

  PatientModel({
    required this.id,
    required this.userId,
    this.gender,
    this.birthDate,
    this.address,
    this.bloodType,
    required this.user,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    // الباك إند بيرجع بيانات الـ user flat (first_name, last_name, email...)
    // مش nested جوا 'user' أو 'User'
    final userJson = json['User'] ?? json['user'] ?? {
      'id': json[ApiKey.userId] ?? 0,
      'first_name': json[ApiKey.firstName],
      'last_name': json[ApiKey.lastName],
      'email': json[ApiKey.email],
      'phone': json[ApiKey.phone],
      'role': json[ApiKey.role],
      'email_verified_at': json[ApiKey.emailVerifiedAt],
    };

    return PatientModel(
      id: json[ApiKey.id] ?? 0,
      userId: json[ApiKey.userId] ?? 0,
      gender: json[ApiKey.gender],
      birthDate: json[ApiKey.birthDate],
      address: json[ApiKey.address],
      bloodType: json[ApiKey.bloodType],
      user: UserModel.fromJson(userJson),
    );
  }
}