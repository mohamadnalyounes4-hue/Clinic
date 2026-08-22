class SupportMessageModel {
  final int id;
  final String message;
  final bool isInternal;
  final String author;
  final bool isFromPatient;
  final DateTime? createdAt;

  const SupportMessageModel({
    required this.id,
    required this.message,
    required this.isInternal,
    required this.author,
    required this.isFromPatient,
    required this.createdAt,
  });

  factory SupportMessageModel.fromJson(
    Map<String, dynamic> json, {
    required String patientName,
  }) {
    final author = json['author']?.toString().trim() ?? '';
    final authorRole = json['author_role']?.toString();
    return SupportMessageModel(
      id: _toInt(json['id']),
      message: json['message']?.toString() ?? '',
      isInternal: json['is_internal'] == true || json['is_internal'] == 1,
      author: author,
      isFromPatient:
          authorRole == 'patient' ||
          _normalize(author) == _normalize(patientName),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
