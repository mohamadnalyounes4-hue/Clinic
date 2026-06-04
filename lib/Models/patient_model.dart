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
    return PatientModel(
      id: json[ApiKey.id],
      userId: json[ApiKey.userId],
      gender: json[ApiKey.gender],
      birthDate: json[ApiKey.birthDate],
      address: json[ApiKey.address],
      bloodType: json[ApiKey.bloodType],
      // الباك بيرجع 'User' بـ uppercase لأن العلاقة اسمها User في الـ model
      // نتعامل مع الحالتين
      user: UserModel.fromJson(
        json['User'] ?? json['user'],
      ),
    );
  }
}