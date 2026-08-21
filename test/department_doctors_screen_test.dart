import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabad/Cubits/cubits/doctor_cubit.dart';
import 'package:nabad/Models/department_model.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/screens/HomePage_patient/doctor/department_doctors_screen.dart';

void main() {
  testWidgets('department page shows only its doctors and filters by name', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final cubit = DoctorCubit(api: _DepartmentDoctorsApi());
    addTearDown(cubit.close);
    await cubit.getDoctorsByDepartment(3);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          home: DepartmentDoctorsScreen(
            department: DepartmentModel(id: 3, department_name: 'أمراض القلب'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('أمراض القلب'), findsWidgets);
    expect(find.text('د. أحمد العلي'), findsOneWidget);
    expect(find.text('د. سارة حسن'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'ابحث عن طبيب بالاسم...'),
      'سارة',
    );
    await tester.pump();

    expect(find.text('د. أحمد العلي'), findsNothing);
    expect(find.text('د. سارة حسن'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _DepartmentDoctorsApi extends ApiConsumer {
  @override
  Future<dynamic> get(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async {
    return {
      'data': [
        {
          'id': 11,
          'user_id': 21,
          'department_id': 3,
          'specialization': 'أمراض القلب',
          'years_of_experience': 8,
          'user': {
            'id': 21,
            'first_name': 'أحمد',
            'last_name': 'العلي',
            'email': 'ahmad@example.com',
            'phone': '0991111111',
            'role': 'doctor',
          },
        },
        {
          'id': 12,
          'user_id': 22,
          'department_id': 3,
          'specialization': 'أمراض القلب',
          'years_of_experience': 5,
          'user': {
            'id': 22,
            'first_name': 'سارة',
            'last_name': 'حسن',
            'email': 'sara@example.com',
            'phone': '0992222222',
            'role': 'doctor',
          },
        },
      ],
    };
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
