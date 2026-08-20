import 'package:flutter_test/flutter_test.dart';
import 'package:nabad/Cubits/states/doctor_dashboard_state.dart';
import 'package:nabad/Models/doctor_dashboard_model.dart';

void main() {
  group('doctor dashboard parsing', () {
    test('matches the authenticated user with the doctor directory entry', () {
      final profile = DoctorDashboardProfile.fromResponses(
        cachedUserId: 12,
        userResponse: {
          'data': {
            'id': 12,
            'first_name': 'سمير',
            'last_name': 'المنصوري',
            'email': 'doctor@example.com',
            'phone': '0999999999',
            'role': 'doctor',
          },
        },
        doctorsResponse: {
          'data': {
            'data': [
              {
                'id': 8,
                'user_id': 12,
                'first_name': 'سمير',
                'last_name': 'المنصوري',
                'specialization': 'قلبية',
              },
            ],
          },
        },
      );

      expect(profile.doctorId, 8);
      expect(profile.fullName, 'سمير المنصوري');
      expect(profile.specialization, 'قلبية');
    });

    test('reads nested patient data from a doctor appointment', () {
      final appointment = DoctorAppointment.fromJson({
        'id': 44,
        'appointment_date': '2026-08-20',
        'appointment_time': '10:30:00',
        'Appointment_duration': '20 minutes',
        'status': 'confirmed',
        'patient': {
          'id': 5,
          'user': {
            'first_name': 'أحمد',
            'last_name': 'العلي',
            'phone': '0911111111',
          },
        },
      });

      expect(appointment.patientName, 'أحمد العلي');
      expect(appointment.patientId, 5);
      expect(appointment.durationMinutes, 20);
      expect(appointment.time, '10:30');
    });

    test('unwraps Laravel paginated lists', () {
      final result = unwrapList({
        'data': {
          'current_page': 1,
          'data': [
            {'id': 1},
            {'id': 2},
          ],
        },
      });

      expect(result.length, 2);
    });

    test('calculates upcoming appointments without fixed UI values', () {
      final future = DateTime.now().add(const Duration(days: 1));
      final date =
          '${future.year.toString().padLeft(4, '0')}-'
          '${future.month.toString().padLeft(2, '0')}-'
          '${future.day.toString().padLeft(2, '0')}';
      final appointment = DoctorAppointment.fromJson({
        'id': 1,
        'appointment_date': date,
        'appointment_time': '09:00',
        'status': 'confirmed',
      });
      final state = DoctorDashboardState(appointments: [appointment]);

      expect(state.nextAppointment?.id, 1);
      expect(state.upcomingAppointments, hasLength(1));
    });

    test('serializes a manually entered medicine without a medicine id', () {
      const medicine = VisitMedicineInput(
        medicineId: 0,
        name: 'باراسيتامول',
        dosage: '500mg',
        frequency: 'كل 8 ساعات',
        duration: '3 أيام',
        notes: '',
      );

      final json = medicine.toApiJson();

      expect(json['medicine_name'], 'باراسيتامول');
      expect(json['name'], 'باراسيتامول');
      expect(json.containsKey('medicine_id'), isFalse);
    });
  });
}
