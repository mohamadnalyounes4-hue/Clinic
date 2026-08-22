import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/states/support_state.dart';
import 'package:nabad/Models/support_ticket_model.dart';
import 'package:nabad/Repositories/support_repository.dart';
import 'package:nabad/core/Error/exceptions.dart';

class SupportCubit extends Cubit<SupportState> {
  final SupportRepository repository;

  SupportCubit({required this.repository}) : super(const SupportState());

  Future<void> loadTickets({bool refresh = false, int? selectTicketId}) async {
    if (state.refreshing ||
        (state.status == SupportLoadStatus.loading && !refresh)) {
      return;
    }
    emit(
      state.copyWith(
        status: state.tickets.isEmpty
            ? SupportLoadStatus.loading
            : state.status,
        refreshing: refresh && state.tickets.isNotEmpty,
        clearError: true,
      ),
    );
    try {
      final tickets = await repository.getTickets();
      final selectedId = selectTicketId ?? state.selectedTicket?.id;
      emit(
        state.copyWith(
          status: SupportLoadStatus.success,
          tickets: tickets,
          selectedTicket: _byId(tickets, selectedId),
          clearSelected:
              selectedId != null && _byId(tickets, selectedId) == null,
          refreshing: false,
          clearError: true,
        ),
      );
    } on ServerExceptions catch (error) {
      emit(
        state.copyWith(
          status: state.tickets.isEmpty
              ? SupportLoadStatus.failure
              : state.status,
          refreshing: false,
          errorMessage: _message(error),
          errorStatusCode: error.statusCode,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SupportLoadStatus.failure,
          refreshing: false,
          errorMessage: 'تعذر الاتصال بالسيرفر. تحقق من الإنترنت وحاول مجدداً.',
        ),
      );
    }
  }

  Future<void> openTicket(int ticketId) async {
    final ticket = _byId(state.tickets, ticketId);
    if (ticket != null) {
      emit(state.copyWith(selectedTicket: ticket, clearActionError: true));
    }
    await loadTickets(refresh: true, selectTicketId: ticketId);
  }

  Future<bool> sendMessage(int ticketId, String value) async {
    final message = value.trim();
    if (message.isEmpty || state.sending) return false;
    emit(state.copyWith(sending: true, clearActionError: true));
    try {
      await repository.sendMessage(ticketId: ticketId, message: message);
      final tickets = await repository.getTickets();
      emit(
        state.copyWith(
          status: SupportLoadStatus.success,
          tickets: tickets,
          selectedTicket: _byId(tickets, ticketId),
          sending: false,
          clearActionError: true,
        ),
      );
      return true;
    } on ServerExceptions catch (error) {
      emit(
        state.copyWith(
          sending: false,
          actionError: _message(error),
          actionStatusCode: error.statusCode,
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          sending: false,
          actionError: 'انقطع الاتصال. لم تُرسل الرسالة والنص ما زال محفوظاً.',
        ),
      );
      return false;
    }
  }

  Future<SupportTicketModel?> createTicket({
    required String subject,
    required String description,
    required String priority,
  }) async {
    if (state.creating) return null;
    emit(state.copyWith(creating: true, clearActionError: true));
    try {
      final created = await repository.createTicket(
        subject: subject.trim(),
        description: description.trim(),
        priority: priority,
      );
      final tickets = await repository.getTickets();
      final selected = _byId(tickets, created.id) ?? created;
      emit(
        state.copyWith(
          status: SupportLoadStatus.success,
          tickets: tickets,
          selectedTicket: selected,
          creating: false,
          clearActionError: true,
        ),
      );
      return selected;
    } on ServerExceptions catch (error) {
      emit(
        state.copyWith(
          creating: false,
          actionError: _message(error),
          actionStatusCode: error.statusCode,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          creating: false,
          actionError: 'تعذر الاتصال. بيانات الشكوى ما زالت محفوظة.',
        ),
      );
    }
    return null;
  }

  void clearActionError() => emit(state.copyWith(clearActionError: true));

  static SupportTicketModel? _byId(List<SupportTicketModel> tickets, int? id) {
    if (id == null) return null;
    for (final ticket in tickets) {
      if (ticket.id == id) return ticket;
    }
    return null;
  }

  static String _message(ServerExceptions error) {
    switch (error.statusCode) {
      case 401:
        return 'انتهت الجلسة. يرجى تسجيل الدخول مجدداً.';
      case 403:
        return 'ليس لديك صلاحية لتنفيذ هذا الإجراء.';
      case 404:
        return 'المحادثة أو البيانات المطلوبة غير موجودة.';
      default:
        return error.errModel.errorMessage;
    }
  }
}
