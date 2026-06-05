class DepartmentModel {
  final int id;
  final String department_name;

  DepartmentModel({
    required this.id,
    required this.department_name,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'],
      department_name: json['department_name'] ?? '',
    );
  }
}