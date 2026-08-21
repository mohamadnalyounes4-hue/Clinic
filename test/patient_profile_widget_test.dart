import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabad/Cubits/cubits/appointment_cubit.dart';
import 'package:nabad/Cubits/cubits/medicine_reminder_cubit.dart';
import 'package:nabad/Cubits/cubits/patient_medical_record_cubit.dart';
import 'package:nabad/Cubits/cubits/user_cubit.dart';
import 'package:nabad/Repositories/user_repository.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';
import 'package:nabad/core/Cache/cache_helper.dart';
import 'package:nabad/core/notifications/medicine_reminder_service.dart';
import 'package:nabad/screens/HomePage_patient/patient_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'patient profile shows personal information, wallet and settings',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await CacheHelper.init();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final api = _PatientProfileApi();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) =>
                  UserCubit(userRepository: UserRepository(api: api)),
            ),
            BlocProvider(create: (_) => AppointmentCubit(api: api)),
            BlocProvider(create: (_) => PatientMedicalRecordCubit(api: api)),
            BlocProvider(
              create: (_) => MedicineReminderCubit(
                service: MedicineReminderService.instance,
              ),
            ),
          ],
          child: const MaterialApp(home: PatientProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('المعلومات الشخصية'), findsOneWidget);
      expect(find.text('محفظتي'), findsOneWidget);
      expect(find.text('وصفاتي الطبية'), findsNothing);
      expect(find.text('تحالِيلي وإحالات المختبر'), findsNothing);
      expect(find.text('استشاراتي'), findsNothing);
      expect(find.text('الإعدادات'), findsOneWidget);
      expect(find.text('معلومات التواصل'), findsNothing);

      await tester.ensureVisible(find.text('المعلومات الشخصية'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('المعلومات الشخصية'));
      await tester.pumpAndSettle();

      expect(find.text('معلومات التواصل'), findsOneWidget);
      expect(find.text('0911111111'), findsOneWidget);
      expect(find.text('patient@example.com'), findsOneWidget);
      expect(find.text('دمشق'), findsOneWidget);
      expect(find.text('أنثى'), findsOneWidget);
      expect(find.text('2000-01-02'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _PatientProfileApi extends ApiConsumer {
  @override
  Future<dynamic> get(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async {
    if (path == EndPoints.profilePatient) {
      return {
        'data': {
          'id': 5,
          'user_id': 7,
          'first_name': 'سارة',
          'last_name': 'العلي',
          'email': 'patient@example.com',
          'phone': '0911111111',
          'email_verified_at': '2026-08-20T10:00:00Z',
          'role': 'patient',
          'gender': 'female',
          'birth_date': '2000-01-02',
          'address': 'دمشق',
          'blood_type': 'A+',
        },
      };
    }
    if (path == EndPoints.appointments ||
        path == EndPoints.patientMedicalRecords ||
        path == EndPoints.prescriptions) {
      return {'data': <dynamic>[]};
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
