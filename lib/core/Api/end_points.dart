class EndPoints {
  static String baseUrl = "http://10.0.2.2:8000/api/"; // Android emulator

  // Auth
  static String login = "login";
  static String signUp = "register";
  static String logout = "logout";
  static String verifyOtp = "verify-otp";
  static String resendOtp = "resend-otp";
  static String currentUser = "user";

  // Patient
  static String completeProfile = "complete_profile";
  static String profilePatient = "profile_patient";
  static String deletePatient(Object id) => "delete_patient/$id";

  // Departments
  static String departments = "departments";
  static String departmentsOnly = "departments_list";
  static String updateDepartment(Object id) => "departments/$id";
  static String deleteDepartment(Object id) => "departments/$id";

  // Doctors
  static String addDoctor = "doctor";
  static String allDoctors = "all_doctors";
  static String doctorsByDepartment(Object id) => "doctor_department/$id";
  static String doctorById(Object id) => "doctor/$id";
  static String deleteDoctor(Object id) => "delete_doctor/$id";
  static String doctorSchedule(Object id) => "doctor_schedule/$id";
  static String doctorAvailableDates(Object id) =>
      "doctors/$id/available-dates";
  static String doctorAvailability(Object id) => "doctors/$id/availability";
  static String myDoctorAppointments = "doctor/appointments/mine";
  static String doctorEarnings = "doctor/earnings";
  static String doctorAppointments = "doctor/appointments";
  static String allAppointments = "all_appointments";

  // Doctor workspace
  static String doctorMedicalRecords = "medical_record_doctor";
  static String patientMedicalRecords = "medical_record_patient";
  static String patientPrescriptions = "patient/prescriptions";
  static String patientPrescriptionById(Object id) =>
      "patient/prescriptions/$id";
  static String medicalRecords = "medical_record";
  static String medicalRecordById(Object id) => "medical_record/$id";
  static String prescriptions = "prescriptions";
  static String prescriptionById(Object id) => "prescriptions/$id";
  static String deletePrescription(Object id) => "delete_prescription/$id";
  static String medicines = "medicines";
  static String medicinesList = "medicines_list";

  // Notifications
  static String notifications = "notifications";
  static String unreadNotificationsCount = "notifications/unread-count";
  static String readNotification(Object id) => "notifications/$id/read";
  static String readAllNotifications = "notifications/read-all";
  static String notificationFcmToken = "notifications/fcm-token";

  // Patient support
  static String patientSupportTickets = "patient/support/tickets";
  static String patientSupportTicketMessages(Object id) =>
      "patient/support/tickets/$id/messages";

  // Appointments
  static String appointments = "appointments"; // GET (list) / POST (book)
  static String updateAppointment(Object id) =>
      "appointments/$id"; // PUT (reschedule) — بس لو confirmed
  static String rateAppointment(Object id) =>
      "appointments/$id/rate"; // POST — بس لو completed

  // "appointments_cancel/{id}" مسجل تحت صلاحية secretary فقط.
  // "المريض لا يملك route إلغاء مباشر" — نص صريح من الباك إند.
  static String cancelAppointment(Object id) => "appointments_cancel/$id";

  // Loyalty Points
  static String points = "points";
  static String pointsTransactions = "points/transactions";
  static String pointsPreview = "points/preview";

  // Wallet
  static String wallet = "wallet";
  static String walletTransactions = "wallet/transactions";
}

class ApiKey {
  static String status = "status";
  static String message = "message";
  static String errorMessage = "errorMessage";
  static String token = "token";
  static String id = "id";
  static String role = "role";

  // User
  static String firstName = "first_name";
  static String lastName = "last_name";
  static String email = "email";
  static String phone = "phone";
  static String password = "password";
  static String emailVerifiedAt = "email_verified_at";

  // Patient
  static String gender = "gender";
  static String birthDate = "birth_date";
  static String address = "address";
  static String bloodType = "blood_type";

  // Doctor
  static String departmentId = "department_id";
  static String specialization = "specialization";
  static String certificate = "certificate";
  static String yearsOfExperience = "years_of_experience";
  static String profileImage = "profile_image";
  static String userId = "user_id";
}
