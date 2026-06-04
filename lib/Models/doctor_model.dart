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
    final userData = json['user'] ?? json['User'];

    return DoctorModel(
      id: json[ApiKey.id] ?? json['id'],
      userId: json[ApiKey.userId] ?? json['user_id'] ?? 0,
      departmentId: json[ApiKey.departmentId] ?? json['department_id'],
      specialization: json[ApiKey.specialization] ?? json['specialization'],
      certificate: json[ApiKey.certificate] ?? json['certificate'],
      yearsOfExperience:
          json[ApiKey.yearsOfExperience] ?? json['years_of_experience'],
      // الصورة مخزنة كـ path مثل 'doctors/xyz.jpg'
      // لازم نضيف base URL + storage/
      profileImage: _buildImageUrl(
        json[ApiKey.profileImage] ?? json['profile_image'],
      ),
      user: UserModel.fromJson(userData),
    );
  }

  static String? _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    // لو كان URL كامل خليه
    if (path.startsWith('http')) return path;
    // ضيف base URL - نفس الـ IP من end_points
    return 'http://192.168.1.3:8000/storage/$path';
  }
}
