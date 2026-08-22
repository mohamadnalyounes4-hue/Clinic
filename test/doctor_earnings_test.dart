import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabad/Cubits/cubits/doctor_earnings_cubit.dart';
import 'package:nabad/Cubits/states/doctor_earnings_state.dart';
import 'package:nabad/Models/doctor_earnings_model.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';
import 'package:nabad/core/localization/app_localizations.dart';
import 'package:nabad/screens/HomePage_doctor/doctor_earnings_page.dart';

void main() {
  test('earnings model uses the server shares without recalculating them', () {
    final earnings = DoctorEarningsModel.fromJson({
      'data': {
        'summary': {
          'appointments': 2,
          'gross': 500,
          'doctor_share': 333,
          'platform_share': 167,
        },
        'ledger': [
          {
            'appointment_id': 12,
            'date': '2026-08-25',
            'gross': 200,
            'doctor_share': 131,
            'platform_share': 69,
          },
        ],
      },
    });

    expect(earnings.summary.doctorShare, 333);
    expect(earnings.summary.platformShare, 167);
    expect(earnings.ledger.single.doctorShare, 131);
    expect(earnings.ledger.single.platformShare, 69);
  });

  testWidgets('earnings page loads the API and renders its ledger in RTL', (
    tester,
  ) async {
    final api = _EarningsApi();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => DoctorEarningsCubit(api: api),
        child: const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: DoctorEarningsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(api.requestedPath, EndPoints.doctorEarnings);
    expect(find.text('صافي أرباحك'), findsOneWidget);
    expect(find.text('1,050 ل.س'), findsOneWidget);
    expect(find.text('الموعد رقم 12'), findsOneWidget);
    expect(find.text('+105'), findsOneWidget);
    expect(
      tester
          .widget<Directionality>(find.byType(Directionality).first)
          .textDirection,
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });

  test('earnings cubit prevents duplicate requests', () async {
    final api = _EarningsApi(delay: const Duration(milliseconds: 20));
    final cubit = DoctorEarningsCubit(api: api);
    addTearDown(cubit.close);

    await Future.wait([cubit.load(), cubit.load()]);

    expect(api.calls, 1);
    expect(cubit.state, isA<DoctorEarningsSuccess>());
  });
}

class _EarningsApi extends ApiConsumer {
  final Duration delay;
  int calls = 0;
  String? requestedPath;

  _EarningsApi({this.delay = Duration.zero});

  @override
  Future<dynamic> get(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async {
    calls++;
    requestedPath = path;
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    return {
      'data': {
        'summary': {
          'appointments': 10,
          'gross': 1500,
          'doctor_share': 1050,
          'platform_share': 450,
        },
        'ledger': [
          {
            'appointment_id': 12,
            'date': '2026-08-25',
            'gross': 150,
            'doctor_share': 105,
            'platform_share': 45,
          },
        ],
      },
    };
  }

  @override
  Future<dynamic> post(
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

  @override
  Future<dynamic> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) => throw UnimplementedError();
}
