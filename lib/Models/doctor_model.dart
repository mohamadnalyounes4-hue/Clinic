import 'package:nabad/Models/user_model.dart';
import 'package:nabad/core/Api/end_points.dart';

class DoctorModel {
  final int id;
  final int userId;
  final int? departmentId;
  final String? specialization;
  final String? certificate;
  final int? yearsOfExperience;
  final String? profileImage;
  final UserModel user;

  DoctorModel({
    required this.id,
    required this.userId,
    this.departmentId,
    this.specialization,
    this.certificate,
    this.yearsOfExperience,
    this.profileImage,
    required this.user,
  });

  String get fullName => '${user.firstName} ${user.lastName}';

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    final bool hasNestedUser = json['user'] != null || json['User'] != null;

    UserModel userModel;

    if (hasNestedUser) {
      // doctorsByDepartment → بيرجع raw model مع user nested
      final userData = json['user'] ?? json['User'];
      userModel = UserModel.fromJson(userData);
    } else {
      // getAllDoctors → DoctorResource بيرجع flat (first_name, last_name مباشرة)
      userModel = UserModel.fromJson({
        'id':                json['user_id'] ?? 0,
        'first_name':        json['first_name'] ?? '',
        'last_name':         json['last_name'] ?? '',
        'email':             json['email'] ?? '',
        'phone':             json['phone'] ?? '',
        'role':              json['role'] ?? 'doctor',
        'email_verified_at': json['email_verified_at'],
      });
    }

    return DoctorModel(
      id:                json[ApiKey.id] ?? json['id'],
      userId:            json[ApiKey.userId] ?? json['user_id'] ?? 0,
      departmentId:      json[ApiKey.departmentId] ?? json['department_id'],
      specialization:    json[ApiKey.specialization] ?? json['specialization'],
      certificate:       json[ApiKey.certificate] ?? json['certificate'],
      yearsOfExperience: json[ApiKey.yearsOfExperience] ?? json['years_of_experience'],
      profileImage:      _buildImageUrl(json[ApiKey.profileImage] ?? json['profile_image']),
      user:              userModel,
    );
  }

  // الباك بيرجع full URL من asset() في DoctorResource
  // لكن لو جاء path فقط (من doctorsByDepartment) نبني الـ URL يدوياً
  static String? _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return 'http://192.168.1.3:8000/storage/$path';
  }
}