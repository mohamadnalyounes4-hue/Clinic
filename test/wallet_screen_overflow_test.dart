import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabad/Cubits/cubits/wallet_cubit.dart';
import 'package:nabad/Models/wallet_model.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';
import 'package:nabad/core/localization/app_localizations.dart';
import 'package:nabad/screens/HomePage_patient/wallet_screen.dart';

void main() {
  test('wallet uses the server direction for doctor and patient movements', () {
    WalletTransactionModel transaction(String type, String direction) =>
        WalletTransactionModel.fromJson({
          'id': 1,
          'type': type,
          'direction': direction,
          'amount': 120,
        });

    expect(transaction('appointment_earning', 'credit').isCredit, isTrue);
    expect(transaction('appointment_refund', 'debit').isCredit, isFalse);
    expect(transaction('appointment_payment', 'debit').isCredit, isFalse);
    expect(transaction('appointment_refund', 'credit').isCredit, isTrue);
  });

  for (final scenario in [
    (locale: const Locale('ar'), allowTopUp: true, title: 'محفظتي'),
    (locale: const Locale('en'), allowTopUp: false, title: 'محفظة الدكتور'),
  ]) {
    testWidgets(
      'wallet transaction cards do not overflow for ${scenario.locale.languageCode}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          BlocProvider(
            create: (_) => WalletCubit(api: _WalletApi()),
            child: MaterialApp(
              locale: scenario.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: WalletScreen(
                title: scenario.title,
                allowTopUp: scenario.allowTopUp,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Refund for cancelled appointment'),
          findsOneWidget,
        );
        expect(
          find.text(
            scenario.locale.languageCode == 'ar'
                ? '+123456789 ل.س'
                : '+123456789 SYP',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _WalletApi extends ApiConsumer {
  @override
  Future<dynamic> get(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async {
    if (path == EndPoints.wallet) {
      return {
        'data': {
          'id': 1,
          'balance': 987654321,
          'user': {'id': 10, 'name': 'Wallet User'},
        },
      };
    }

    if (path == EndPoints.walletTransactions) {
      return {
        'data': [
          {
            'id': 1,
            'type': 'appointment_refund',
            'direction': 'credit',
            'amount': 123456789,
            'description':
                'Refund for cancelled appointment #123456789 with an exceptionally long reference description',
            'created_at': '2026-08-22T12:00:00Z',
          },
        ],
      };
    }

    return const <String, dynamic>{};
  }

  @override
  Future<dynamic> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async => const <String, dynamic>{};

  @override
  Future<dynamic> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async => const <String, dynamic>{};

  @override
  Future<dynamic> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async => const <String, dynamic>{};
}
