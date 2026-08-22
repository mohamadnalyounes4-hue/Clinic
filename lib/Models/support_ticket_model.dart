import 'package:nabad/Models/support_message_model.dart';

class SupportTicketModel {
  final int id;
  final String subject;
  final String description;
  final String priority;
  final String status;
  final int messagesCount;
  final String patientName;
  final String? assignee;
  final DateTime? createdAt;
  final List<SupportMessageModel> messages;

  const SupportTicketModel({
    required this.id,
    required this.subject,
    required this.description,
    required this.priority,
    required this.status,
    required this.messagesCount,
    required this.patientName,
    required this.assignee,
    required this.createdAt,
    required this.messages,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    final patient = (json['patient'] as Map?)?.cast<String, dynamic>() ?? {};
    final patientName = patient['name']?.toString().trim() ?? '';
    final rawMessages = json['messages'];
    final messages = rawMessages is List
        ? rawMessages
              .whereType<Map>()
              .map(
                (item) => SupportMessageModel.fromJson(
                  item.cast<String, dynamic>(),
                  patientName: patientName,
                ),
              )
              .where(
                (item) => !item.isInternal && item.message.trim().isNotEmpty,
              )
              .toList()
        : <SupportMessageModel>[];
    messages.sort((a, b) {
      if (a.createdAt != null && b.createdAt != null) {
        return a.createdAt!.compareTo(b.createdAt!);
      }
      return a.id.compareTo(b.id);
    });

    return SupportTicketModel(
      id: _toInt(json['id']),
      subject: json['subject']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'normal',
      status: json['status']?.toString() ?? 'open',
      messagesCount: _toInt(json['messages_count']),
      patientName: patientName,
      assignee: json['assignee']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      messages: List.unmodifiable(messages),
    );
  }

  String get lastMessage =>
      messages.isNotEmpty ? messages.last.message : description;

  DateTime? get lastActivityAt =>
      messages.isNotEmpty ? messages.last.createdAt ?? createdAt : createdAt;

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
