import 'package:nabad/Models/support_ticket_model.dart';
import 'package:nabad/Services/support_service.dart';

class SupportRepository {
  final SupportService service;

  const SupportRepository({required this.service});

  Future<List<SupportTicketModel>> getTickets() async {
    final response = await service.getTickets();
    final raw = response['data'];
    if (raw is! List) return const [];
    final tickets = raw
        .whereType<Map>()
        .map(
          (item) => SupportTicketModel.fromJson(item.cast<String, dynamic>()),
        )
        .toList();
    tickets.sort((a, b) {
      final left = a.lastActivityAt;
      final right = b.lastActivityAt;
      if (left == null && right == null) return b.id.compareTo(a.id);
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });
    return tickets;
  }

  Future<SupportTicketModel> createTicket({
    required String subject,
    required String description,
    required String priority,
  }) async {
    final response = await service.createTicket(
      subject: subject,
      description: description,
      priority: priority,
    );
    return SupportTicketModel.fromJson(
      (response['data'] as Map).cast<String, dynamic>(),
    );
  }

  Future<void> sendMessage({
    required int ticketId,
    required String message,
  }) async {
    await service.sendMessage(ticketId: ticketId, message: message);
  }
}
