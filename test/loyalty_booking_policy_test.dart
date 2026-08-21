import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabad/Cubits/cubits/appointment_cubit.dart';
import 'package:nabad/Cubits/cubits/points_cubit.dart';
import 'package:nabad/Cubits/cubits/wallet_cubit.dart';
import 'package:nabad/Models/doctor_model.dart';
import 'package:nabad/Models/points_model.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';
import 'package:nabad/core/localization/app_localizations.dart';
import 'package:nabad/screens/HomePage_patient/booking_detail_screen.dart';

void main() {
  group('loyalty policy', () {
    test('awards 20 points and unlocks one 30% discount at 40 points', () {
      expect(LoyaltyPolicy.pointsAwardedPerAppointment, 20);
      expect(LoyaltyPolicy.canRedeem(39), isFalse);
      expect(LoyaltyPolicy.canRedeem(40), isTrue);
      expect(LoyaltyPolicy.pointsRequiredForDiscount, 40);
      expect(LoyaltyPolicy.discountPercentage, 30);
    });

    test(
      'uses the fixed policy even when the server advertises an old rate',
      () {
        final summary = PointsSummaryModel.fromJson({
          'data': {
            'points_balance': 60,
            'loyalty_active': true,
            'settings': {'redemption_rate': '100 points = 10% max 50%'},
          },
        });

        expect(summary.pointsPerUnit, 40);
        expect(summary.discountPerUnit, 30);
        expect(summary.maxDiscountPercent, 30);
        expect(summary.discountPercentFor(0), 0);
        expect(summary.discountPercentFor(40), 30);
        expect(summary.discountPercentFor(80), 0);
      },
    );

    test('rounds the discounted amount used for wallet settlement', () {
      expect(LoyaltyPolicy.discountAmount(999), 299.70);
      expect(LoyaltyPolicy.finalPrice(999), 699.30);
      expect(LoyaltyPolicy.finalPrice(1000), 700);
    });

    test('accepts only a financially consistent server preview', () {
      const valid = PointsRedemptionPreviewModel(
        loyaltyActive: true,
        patientPointsBalance: 40,
        originalPrice: 1000,
        pointsRedeemed: 40,
        discountPercentage: 30,
        discountAmount: 300,
        finalPrice: 700,
      );
      const wrongDoctorAmount = PointsRedemptionPreviewModel(
        loyaltyActive: true,
        patientPointsBalance: 40,
        originalPrice: 1000,
        pointsRedeemed: 40,
        discountPercentage: 30,
        discountAmount: 300,
        finalPrice: 800,
      );

      expect(valid.matchesLoyaltyPolicy(consultationFee: 1000), isTrue);
      expect(
        wrongDoctorAmount.matchesLoyaltyPolicy(consultationFee: 1000),
        isFalse,
      );
    });
  });

  group('booking API contract', () {
    test(
      'sends only the 40-point choice and leaves money to the server',
      () async {
        final api = _BookingApi();
        final cubit = AppointmentCubit(api: api);
        addTearDown(cubit.close);

        await cubit.bookAppointment(
          doctorId: 8,
          date: DateTime(2026, 8, 25),
          time: '10:30',
          pointsToRedeem: 40,
        );

        expect(api.bookingData?['points_to_redeem'], 40);
        expect(api.bookingData, isNot(contains('price')));
        expect(api.bookingData, isNot(contains('discount_amount')));
        expect(api.bookingData, isNot(contains('final_price')));
      },
    );

    test('rejects any partial or unexpected points amount', () async {
      final api = _BookingApi();
      final cubit = AppointmentCubit(api: api);
      addTearDown(cubit.close);

      await expectLater(
        cubit.bookAppointment(
          doctorId: 8,
          date: DateTime(2026, 8, 25),
          time: '10:30',
          pointsToRedeem: 20,
        ),
        throwsArgumentError,
      );
      expect(api.bookingData, isNull);
    });
  });

  testWidgets('eligible patient chooses full price or the 40-point price', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = _BookingApi();
    final doctor = DoctorModel.fromJson({
      'id': 8,
      'user_id': 12,
      'first_name': 'سمير',
      'last_name': 'الطبيب',
      'specialization': 'Cardiology',
      'consultation_fee': 1000,
    });

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AppointmentCubit(api: api)),
          BlocProvider(create: (_) => PointsCubit(api: api)),
          BlocProvider(create: (_) => WalletCubit(api: api)),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: BookingDetailScreen(doctor: doctor),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('حجز عادي بالسعر الكامل'), findsOneWidget);
    expect(find.text('استخدام 40 نقطة'), findsOneWidget);
    expect(find.text('خصم 30% على هذا الحجز'), findsOneWidget);

    await tester.ensureVisible(find.text('استخدام 40 نقطة'));
    await tester.tap(find.text('استخدام 40 نقطة'));
    await tester.pumpAndSettle();

    expect(api.previewData?['points_to_redeem'], 40);
    expect(find.text('700 ر.س'), findsWidgets);
    expect(find.text('خصم 30%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _BookingApi extends ApiConsumer {
  Map<String, dynamic>? bookingData;
  Map<String, dynamic>? previewData;

  @override
  Future<dynamic> get(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async {
    if (path == EndPoints.appointments) return {'data': <dynamic>[]};
    if (path == EndPoints.points) {
      return {
        'data': {
          'points_balance': 40,
          'loyalty_active': true,
          'settings': {'redemption_rate': '40 points = 30% max 30%'},
        },
      };
    }
    if (path == EndPoints.wallet) {
      return {
        'data': {
          'id': 1,
          'balance': 2000,
          'user': {'id': 5, 'name': 'Patient'},
        },
      };
    }
    if (path == EndPoints.walletTransactions) {
      return {'data': <dynamic>[]};
    }
    if (path == EndPoints.doctorAvailableDates(8)) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      return {
        'data': [
          {'date': _date(tomorrow), 'is_available': true, 'available_slots': 1},
        ],
      };
    }
    if (path == EndPoints.doctorAvailability(8)) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      return {
        'data': {
          'date': _date(tomorrow),
          'is_working_day': true,
          'duration_minutes': 30,
          'slots': [
            {'time': '10:30', 'end_time': '11:00', 'available': true},
          ],
        },
      };
    }
    return <String, dynamic>{};
  }

  @override
  Future<dynamic> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async {
    if (path == EndPoints.pointsPreview) {
      previewData = (data as Map).cast<String, dynamic>();
      return {
        'data': {
          'loyalty_active': true,
          'patient_points_balance': 40,
          'original_price': 1000,
          'points_redeemed': 40,
          'discount_percentage': 30,
          'discount_amount': 300,
          'final_price': 700,
        },
      };
    }
    if (path == EndPoints.appointments) {
      bookingData = (data as Map).cast<String, dynamic>();
      return {
        'data': {
          'id': 1,
          'appointment_date': bookingData!['appointment_date'],
          'appointment_time': bookingData!['appointment_time'],
          'status': 'pending_approval',
          'price': 1000,
          'discount_amount': 300,
          'requested_points_to_redeem': 40,
          'final_price': 700,
          'doctor': {'id': 8, 'name': 'Doctor', 'specialization': 'Cardiology'},
        },
      };
    }
    return <String, dynamic>{};
  }

  @override
  Future<dynamic> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async => <String, dynamic>{};

  @override
  Future<dynamic> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async => <String, dynamic>{};

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
