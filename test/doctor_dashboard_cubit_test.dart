import 'package:flutter_test/flutter_test.dart';
import 'package:nabad/Cubits/cubits/doctor_dashboard_cubit.dart';
import 'package:nabad/Models/doctor_dashboard_model.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';
import 'package:nabad/core/Cache/cache_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({ApiKey.id: 12});
    await CacheHelper.init();
  });

  test('loads appointments from the authenticated doctor endpoint', () async {
    final api = _DashboardApi();
    final cubit = DoctorDashboardCubit(api: api);

    await cubit.loadDashboard();

    expect(cubit.state.appointments, hasLength(1));
    expect(cubit.state.appointments.single.patientName, 'مريض الطبيب');
    expect(cubit.state.appointmentsError, isNull);
    await cubit.close();
  });

  test('creates the medical record before its linked prescription', () async {
    final api = _DashboardApi();
    final cubit = DoctorDashboardCubit(api: api);

    final success = await cubit.completeVisit(
      appointmentId: 44,
      diagnosis: 'التهاب',
      bloodType: 'O+',
      allergies: '',
      heartRate: '72',
      diseases: '',
      notes: 'متابعة',
      referToPharmacist: true,
      referToLaboratory: false,
      laboratoryNotes: '',
      prescriptionInstructions: 'بعد الطعام',
      prescriptionNotes: '',
      medicines: const [
        VisitMedicineInput(
          medicineId: 9,
          name: 'دواء',
          dosage: '500mg',
          frequency: 'كل 12 ساعة',
          duration: '7 أيام',
          notes: '',
        ),
      ],
    );

    expect(success, isTrue);
    expect(api.postPaths.take(2), [
      EndPoints.medicalRecords,
      EndPoints.prescriptions,
    ]);
    expect(api.prescriptionPayload?['medical_record_id'], 77);
    await cubit.close();
  });
}

class _DashboardApi extends ApiConsumer {
  final List<String> postPaths = [];
  Map<String, dynamic>? prescriptionPayload;

  @override
  Future<dynamic> get(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async {
    if (path == EndPoints.currentUser) {
      return {
        'data': {
          'id': 12,
          'first_name': 'سمير',
          'last_name': 'المنصوري',
          'email': 'doctor@example.com',
          'phone': '0999999999',
          'role': 'doctor',
        },
      };
    }
    if (path == EndPoints.allDoctors) {
      return {
        'data': [
          {
            'id': 8,
            'user_id': 12,
            'first_name': 'سمير',
            'last_name': 'المنصوري',
          },
        ],
      };
    }
    if (path == EndPoints.myDoctorAppointments) {
      return {
        'data': [
          {
            'id': 44,
            'doctor_id': 8,
            'appointment_date': '2099-01-01',
            'appointment_time': '10:30',
            'status': 'confirmed',
            'patient': {
              'id': 3,
              'user': {'first_name': 'مريض', 'last_name': 'الطبيب'},
            },
          },
        ],
      };
    }
    if (path == EndPoints.unreadNotificationsCount) return {'count': 0};
    return {'data': <dynamic>[]};
  }

  @override
  Future<dynamic> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async {
    postPaths.add(path);
    if (path == EndPoints.medicalRecords) {
      return {
        'data': {'id': 77},
      };
    }
    if (path == EndPoints.prescriptions) {
      prescriptionPayload = (data as Map).cast<String, dynamic>();
      return {
        'data': {'id': 91},
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
}
