import 'package:flutter_test/flutter_test.dart';
import 'package:nabad/Cubits/cubits/appointment_cubit.dart';
import 'package:nabad/core/Api/api_consumer.dart';
import 'package:nabad/core/Api/end_points.dart';
import 'package:nabad/core/time/clinic_clock.dart';

void main() {
  test(
    'available dates come from the API without local schedule math',
    () async {
      final api = _AvailabilityApi();
      final cubit = AppointmentCubit(api: api);
      addTearDown(cubit.close);
      final from = DateTime(2026, 8, 22);

      final dates = await cubit.getDoctorAvailableDates(
        doctorId: 5,
        from: from,
        to: from.add(const Duration(days: 61)),
      );

      expect(api.path, EndPoints.doctorAvailableDates(5));
      expect(api.query?['from'], '2026-08-22');
      expect(api.query?['to'], '2026-10-22');
      expect(dates, hasLength(2));
      expect(dates.last.availableSlots, 3);
      expect(dates.last.date, DateTime(2026, 8, 25));
    },
  );

  test('availability request rejects more than 62 inclusive days locally', () {
    final cubit = AppointmentCubit(api: _AvailabilityApi());
    addTearDown(cubit.close);
    final from = DateTime(2026, 8, 22);

    expect(
      () => cubit.getDoctorAvailableDates(
        doctorId: 5,
        from: from,
        to: from.add(const Duration(days: 62)),
      ),
      throwsArgumentError,
    );
  });

  test('clinic clock always uses Asia/Damascus', () {
    expect(ClinicClock.now().location.name, ClinicClock.timezoneName);
  });
}

class _AvailabilityApi extends ApiConsumer {
  String? path;
  Map<String, dynamic>? query;

  @override
  Future<dynamic> get(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool isFromData = false,
  }) async {
    this.path = path;
    query = queryParameters;
    return {
      'data': [
        {'date': '2026-08-23', 'is_available': false, 'available_slots': 0},
        {'date': '2026-08-25', 'is_available': true, 'available_slots': 3},
      ],
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
