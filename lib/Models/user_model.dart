import 'package:nabad/core/Api/end_points.dart';

class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final String? emailVerifiedAt;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    this.emailVerifiedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json[ApiKey.id] ?? 0,
      firstName: json[ApiKey.firstName] ?? '',
      lastName: json[ApiKey.lastName] ?? '',
      email: json[ApiKey.email] ?? '',
      phone: json[ApiKey.phone] ?? '',
      role: json[ApiKey.role] ?? '',
      emailVerifiedAt: json[ApiKey.emailVerifiedAt],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.id: id,
      ApiKey.firstName: firstName,
      ApiKey.lastName: lastName,
      ApiKey.email: email,
      ApiKey.phone: phone,
      ApiKey.role: role,
      ApiKey.emailVerifiedAt: emailVerifiedAt,
    };
  }
}
