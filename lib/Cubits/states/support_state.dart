import 'package:nabad/Models/support_ticket_model.dart';

enum SupportLoadStatus { initial, loading, success, failure }

class SupportState {
  final SupportLoadStatus status;
  final List<SupportTicketModel> tickets;
  final SupportTicketModel? selectedTicket;
  final bool refreshing;
  final bool sending;
  final bool creating;
  final String? errorMessage;
  final int? errorStatusCode;
  final String? actionError;
  final int? actionStatusCode;

  const SupportState({
    this.status = SupportLoadStatus.initial,
    this.tickets = const [],
    this.selectedTicket,
    this.refreshing = false,
    this.sending = false,
    this.creating = false,
    this.errorMessage,
    this.errorStatusCode,
    this.actionError,
    this.actionStatusCode,
  });

  SupportState copyWith({
    SupportLoadStatus? status,
    List<SupportTicketModel>? tickets,
    SupportTicketModel? selectedTicket,
    bool clearSelected = false,
    bool? refreshing,
    bool? sending,
    bool? creating,
    String? errorMessage,
    int? errorStatusCode,
    bool clearError = false,
    String? actionError,
    int? actionStatusCode,
    bool clearActionError = false,
  }) {
    return SupportState(
      status: status ?? this.status,
      tickets: tickets ?? this.tickets,
      selectedTicket: clearSelected
          ? null
          : selectedTicket ?? this.selectedTicket,
      refreshing: refreshing ?? this.refreshing,
      sending: sending ?? this.sending,
      creating: creating ?? this.creating,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      errorStatusCode: clearError
          ? null
          : errorStatusCode ?? this.errorStatusCode,
      actionError: clearActionError ? null : actionError ?? this.actionError,
      actionStatusCode: clearActionError
          ? null
          : actionStatusCode ?? this.actionStatusCode,
    );
  }
}
