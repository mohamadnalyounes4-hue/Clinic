import 'package:nabad/Models/user_model.dart';
import 'package:nabad/core/Api/end_points.dart';

class SignUpModel {
  final String message;
  final UserModel user;

  SignUpModel({
    required this.message,
    required this.user,
  });

  factory SignUpModel.fromJson(Map<String, dynamic> json) {
    return SignUpModel(
      message: json[ApiKey.message],
      user: UserModel.fromJson(json['data']),
    );
  }
}