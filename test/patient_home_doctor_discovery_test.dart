import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabad/Cubits/cubits/department_cubit.dart';
import 'package:nabad/Cubits/cubits/doctor_cubit.dart';
import 'package:nabad/Cubits/cubits/patient_notification_cubit.dart';
import 'package:nabad/Cubits/cubits/points_cubit.dart';
import 'package:nabad/Cubits/cubits/user_cubit.dart';
import 'package:nabad/Repositories/user_repository.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';
import 'package:nabad/screens/HomePage_patient/homepage_p.dart';

void main() {
  testWidgets('home shows four suggestions and searches all doctors by name', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = _PatientHomeApi();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => UserCubit(userRepository: UserRepository(api: api)),
          ),
          BlocProvider(create: (_) => DepartmentCubit(api: api)),
          BlocProvider(create: (_) => DoctorCubit(api: api)),
          BlocProvider(create: (_) => PointsCubit(api: api)),
          BlocProvider(create: (_) => PatientNotificationCubit(api: api)),
        ],
        child: const MaterialApp(home: PatientHomePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == 'assets/images/logo.png',
      ),
      findsOneWidget,
    );

    final visibleDoctorNames = find.byWidgetPredicate(
      (widget) =>
          widget is Text && (widget.data?.startsWith('د. طبيب') ?? false),
    );
    expect(visibleDoctorNames, findsNWidgets(4));
    expect(find.text('الأطباء'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextField, 'ابحث عن طبيب بالاسم...'),
      'الخامس',
    );
    await tester.pump();

    expect(find.text('نتائج البحث'), findsOneWidget);
    expect(find.text('د. طبيب الخامس'), findsOneWidget);
    expect(find.text('التخصصات الطبية'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

class _PatientHomeApi extends ApiConsumer {
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
          'first_name': 'مريض',
          'last_name': 'تجريبي',
          'email': 'patient@example.com',
          'phone': '0991234567',
          'role': 'patient',
          'gender': 'male',
          'birth_date': '2000-01-01',
          'address': 'دمشق',
          'blood_type': 'A+',
        },
      };
    }
    if (path == EndPoints.departmentsOnly) {
      return {
        'data': [
          {'id': 3, 'department_name': 'أمراض القلب'},
        ],
      };
    }
    if (path == EndPoints.allDoctors) {
      const names = ['الأول', 'الثاني', 'الثالث', 'الرابع', 'الخامس'];
      return {
        'data': List.generate(
          names.length,
          (index) => {
            'id': index + 1,
            'user_id': index + 20,
            'department_id': 3,
            'first_name': 'طبيب',
            'last_name': names[index],
            'specialization': 'أمراض القلب',
            'years_of_experience': index + 2,
          },
        ),
      };
    }
    if (path == EndPoints.points) {
      return {
        'data': {
          'points_balance': 0,
          'loyalty_active': true,
          'settings': {'redemption_rate': '100 points = 10% max 50%'},
        },
      };
    }
    if (path == EndPoints.unreadNotificationsCount) {
      return {'count': 0};
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
