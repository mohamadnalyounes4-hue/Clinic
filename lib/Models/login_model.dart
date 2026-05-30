import 'package:nabad/Models/user_model.dart';
import 'package:nabad/core/Api/end_points.dart';

class LoginModel {
  final String token;
  final UserModel user;

  LoginModel({
    required this.token,
    required this.user,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      token: json[ApiKey.token],
      user: UserModel.fromJson(json['user']),
    );
  }
}