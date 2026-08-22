import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabad/Cubits/cubits/support_cubit.dart';
import 'package:nabad/Cubits/cubits/patient_notification_cubit.dart';
import 'package:nabad/Cubits/states/support_state.dart';
import 'package:nabad/Models/patient_notification_model.dart';
import 'package:nabad/Models/support_notification_model.dart';
import 'package:nabad/Models/support_ticket_model.dart';
import 'package:nabad/Repositories/support_repository.dart';
import 'package:nabad/Services/support_service.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Error/error_model.dart';
import 'package:nabad/core/Error/exceptions.dart';
import 'package:nabad/core/localization/app_localizations.dart';
import 'package:nabad/core/router/app_router.dart';
import 'package:nabad/screens/HomePage_patient/patient_notifications_screen.dart';
import 'package:nabad/screens/HomePage_patient/support_tickets_page.dart';

void main() {
  group('Support API models', () {
    test('accepts legacy notifications with an empty data array', () {
      final notification = PatientNotificationModel.fromJson({
        'id': 27,
        'type': 'support_message',
        'title': 'Support',
        'body': 'Hello',
        'data': <dynamic>[],
        'is_read': false,
        'created_at': '2026-08-22T10:00:00Z',
      });

      expect(notification.id, 27);
      expect(notification.data, isEmpty);
    });

    test('parses conversations and removes internal messages', () {
      final ticket = SupportTicketModel.fromJson(_ticketJson());

      expect(ticket.id, 17);
      expect(ticket.status, 'closed');
      expect(ticket.priority, 'urgent');
      expect(ticket.messages, hasLength(2));
      expect(ticket.messages.any((item) => item.isInternal), isFalse);
      expect(ticket.messages.first.isFromPatient, isTrue);
      expect(ticket.messages.last.isFromPatient, isFalse);
      expect(ticket.lastMessage, 'رد فريق الدعم');
    });

    test('extracts ticket id only for support reply navigation', () {
      final notification = PatientNotificationModel.fromJson({
        'id': 8,
        'type': 'support_ticket_reply',
        'title': 'Support reply',
        'body': 'New reply',
        'data': {'ticket_id': '17'},
        'is_read': false,
        'created_at': '2026-08-22T10:00:00Z',
      });

      final support = SupportNotificationModel.fromPatientNotification(
        notification,
      );
      expect(support.ticketId, 17);
      expect(support.opensSupportChat, isTrue);
      expect(support.isSupportNotification, isTrue);
    });
  });

  group('Support service', () {
    test('uses patient support endpoints and exact JSON payloads', () async {
      final api = _RecordingApi();
      final service = SupportService(api: api);

      await service.getTickets();
      expect(api.lastMethod, 'GET');
      expect(api.lastPath, 'patient/support/tickets');

      await service.createTicket(
        subject: 'مشكلة في الحجز',
        description: 'شرح المشكلة',
        priority: 'normal',
      );
      expect(api.lastMethod, 'POST');
      expect(api.lastPath, 'patient/support/tickets');
      expect(api.lastData, {
        'subject': 'مشكلة في الحجز',
        'description': 'شرح المشكلة',
        'priority': 'normal',
      });

      await service.sendMessage(ticketId: 17, message: 'نص الرسالة');
      expect(api.lastPath, 'patient/support/tickets/17/messages');
      expect(api.lastData, {'message': 'نص الرسالة'});
    });
  });

  group('Support cubit', () {
    test(
      'prevents duplicate sends and refreshes server-owned status',
      () async {
        final repository = _FakeSupportRepository();
        final cubit = SupportCubit(repository: repository);
        await cubit.loadTickets();
        expect(cubit.state.selectedTicket, isNull);

        await cubit.openTicket(17);
        expect(cubit.state.selectedTicket?.status, 'closed');

        final first = cubit.sendMessage(17, 'hello');
        final duplicate = await cubit.sendMessage(17, 'hello');
        expect(duplicate, isFalse);
        expect(repository.sendCount, 1);

        repository.sent.complete();
        expect(await first, isTrue);
        expect(cubit.state.selectedTicket?.status, 'open');
        expect(repository.loadCount, 3);
        await cubit.close();
      },
    );

    test('surfaces 422 server message without retrying', () async {
      final repository = _FakeSupportRepository(
        sendError: ServerExceptions(
          errModel: ErrorModel(errorMessage: 'الرسالة مطلوبة'),
          statusCode: 422,
        ),
      );
      final cubit = SupportCubit(repository: repository);

      final sent = await cubit.sendMessage(17, 'hello');
      expect(sent, isFalse);
      expect(cubit.state.actionStatusCode, 422);
      expect(cubit.state.actionError, 'الرسالة مطلوبة');
      expect(repository.sendCount, 1);
      expect(repository.loadCount, 0);
      await cubit.close();
    });

    test('maps permission, missing data, and expired session errors', () async {
      for (final entry in <int, String>{
        401: 'انتهت الجلسة',
        403: 'ليس لديك صلاحية',
        404: 'غير موجودة',
      }.entries) {
        final repository = _FakeSupportRepository(
          loadError: ServerExceptions(
            errModel: ErrorModel(errorMessage: 'server'),
            statusCode: entry.key,
          ),
        );
        final cubit = SupportCubit(repository: repository);
        await cubit.loadTickets();
        expect(cubit.state.status, SupportLoadStatus.failure);
        expect(cubit.state.errorStatusCode, entry.key);
        expect(cubit.state.errorMessage, contains(entry.value));
        await cubit.close();
      }
    });
  });

  group('Support localization and direction', () {
    testWidgets('renders Arabic support UI in RTL', (tester) async {
      await _pumpSupportPage(tester, const Locale('ar'));

      expect(find.text('الدعم الفني'), findsOneWidget);
      expect(find.text('محادثاتي وشكاواي'), findsOneWidget);
      final directions = tester.widgetList<Directionality>(
        find.ancestor(
          of: find.text('الدعم الفني'),
          matching: find.byType(Directionality),
        ),
      );
      expect(
        directions.any((item) => item.textDirection == TextDirection.rtl),
        isTrue,
      );
    });

    testWidgets('renders translated English support UI in LTR', (tester) async {
      await _pumpSupportPage(tester, const Locale('en'));

      expect(find.text('Technical support'), findsOneWidget);
      expect(find.text('My conversations and complaints'), findsOneWidget);
      final directions = tester.widgetList<Directionality>(
        find.ancestor(
          of: find.text('Technical support'),
          matching: find.byType(Directionality),
        ),
      );
      expect(
        directions.any((item) => item.textDirection == TextDirection.ltr),
        isTrue,
      );
    });
  });

  testWidgets('support reply notification opens its conversation route', (
    tester,
  ) async {
    final supportCubit = SupportCubit(repository: _FakeSupportRepository());
    final notificationCubit = PatientNotificationCubit(api: _NotificationApi());
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: supportCubit),
          BlocProvider.value(value: notificationCubit),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routes: {
            AppRoutes.supportChat: (_) => const Scaffold(
              body: Center(
                child: Text(
                  'support chat opened',
                  key: Key('support-chat-opened'),
                ),
              ),
            ),
          },
          home: const PatientNotificationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Support replied'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('support-chat-opened')), findsOneWidget);
    addTearDown(supportCubit.close);
    addTearDown(notificationCubit.close);
  });
}

Future<void> _pumpSupportPage(WidgetTester tester, Locale locale) async {
  final cubit = SupportCubit(repository: _FakeSupportRepository());
  await tester.pumpWidget(
    BlocProvider.value(
      value: cubit,
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SupportTicketsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(cubit.close);
}

Map<String, dynamic> _ticketJson({String status = 'closed'}) => {
  'id': 17,
  'subject': 'مشكلة في الحجز',
  'description': 'شرح المشكلة',
  'priority': 'urgent',
  'status': status,
  'messages_count': 3,
  'created_at': '2026-08-22T08:00:00Z',
  'patient': {'id': 2, 'name': 'Ali Patient'},
  'assignee': 'Support Agent',
  'messages': [
    {
      'id': 1,
      'message': 'رسالة المريض',
      'is_internal': false,
      'author': 'Ali Patient',
      'author_role': 'patient',
      'created_at': '2026-08-22T08:01:00Z',
    },
    {
      'id': 2,
      'message': 'ملاحظة داخلية',
      'is_internal': true,
      'author': 'Support Agent',
      'author_role': 'technical_support',
      'created_at': '2026-08-22T08:02:00Z',
    },
    {
      'id': 3,
      'message': 'رد فريق الدعم',
      'is_internal': false,
      'author': 'Support Agent',
      'author_role': 'technical_support',
      'created_at': '2026-08-22T08:03:00Z',
    },
  ],
};

class _RecordingApi implements ApiConsumer {
  String? lastMethod;
  String? lastPath;
  dynamic lastData;

  @override
  Future<dynamic> get(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async {
    lastMethod = 'GET';
    lastPath = path;
    lastData = data;
    return {'data': <dynamic>[]};
  }

  @override
  Future<dynamic> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async {
    lastMethod = 'POST';
    lastPath = path;
    lastData = data;
    return {'data': _ticketJson()};
  }

  @override
  Future<dynamic> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) => throw UnimplementedError();

  @override
  Future<dynamic> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) => throw UnimplementedError();
}

class _FakeSupportRepository extends SupportRepository {
  final ServerExceptions? loadError;
  final ServerExceptions? sendError;
  final Completer<void> sent = Completer<void>();
  int loadCount = 0;
  int sendCount = 0;
  bool replied = false;

  _FakeSupportRepository({this.loadError, this.sendError})
    : super(service: SupportService(api: _RecordingApi()));

  @override
  Future<List<SupportTicketModel>> getTickets() async {
    loadCount++;
    if (loadError != null) throw loadError!;
    return [
      SupportTicketModel.fromJson(
        _ticketJson(status: replied ? 'open' : 'closed'),
      ),
    ];
  }

  @override
  Future<void> sendMessage({
    required int ticketId,
    required String message,
  }) async {
    sendCount++;
    if (sendError != null) throw sendError!;
    await sent.future;
    replied = true;
  }
}

class _NotificationApi implements ApiConsumer {
  Map<String, dynamic> get _notification => {
    'id': 44,
    'type': 'support_ticket_reply',
    'title': 'Support replied',
    'body': 'There is a new support reply.',
    'data': {'ticket_id': 17},
    'is_read': false,
    'created_at': '2026-08-22T10:00:00Z',
  };

  @override
  Future<dynamic> get(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async {
    if (path == 'notifications/unread-count') return {'count': 1};
    if (path == 'notifications') {
      return {
        'data': [_notification],
        'meta': {'current_page': 1, 'last_page': 1},
      };
    }
    throw StateError('Unexpected GET $path');
  }

  @override
  Future<dynamic> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async {
    if (path == 'notifications/44/read') {
      return {
        'data': {..._notification, 'is_read': true},
      };
    }
    if (path == 'notifications/read-all') return {'message': 'ok'};
    throw StateError('Unexpected POST $path');
  }

  @override
  Future<dynamic> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) => throw UnimplementedError();

  @override
  Future<dynamic> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) => throw UnimplementedError();
}
