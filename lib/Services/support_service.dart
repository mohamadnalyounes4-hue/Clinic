import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';

class SupportService {
  final ApiConsumer api;

  const SupportService({required this.api});

  Future<Map<String, dynamic>> getTickets() async {
    final response = await api.get(EndPoints.patientSupportTickets);
    return (response as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> createTicket({
    required String subject,
    required String description,
    required String priority,
  }) async {
    final response = await api.post(
      EndPoints.patientSupportTickets,
      data: {
        'subject': subject,
        'description': description,
        'priority': priority,
      },
    );
    return (response as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> sendMessage({
    required int ticketId,
    required String message,
  }) async {
    final response = await api.post(
      EndPoints.patientSupportTicketMessages(ticketId),
      data: {'message': message},
    );
    return (response as Map).cast<String, dynamic>();
  }
}
