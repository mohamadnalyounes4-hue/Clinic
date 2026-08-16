class EndPoints {
  static String baseUrl = "http://192.168.1.5:8000/api/"; // عالموبايل و بيتغير
  // static String baseUrl = "http://10.0.2.2:8000/api/";          //عالمحاكي

  // Auth
  static String login = "login";
  static String signUp = "register";
  static String logout = "logout";
  static String verifyOtp = "verify-otp";
  static String resendOtp = "resend-otp";

  // Patient
  static String completeProfile = "complete_profile";
  static String profilePatient = "profile_patient";
  static String deletePatient(id) => "delete_patient/$id";

  // Departments
  static String departments = "departments";
  static String departmentsOnly = "departments_list";
  static String updateDepartment(id) => "departments/$id";
  static String deleteDepartment(id) => "departments/$id";

  // Doctors
  static String addDoctor = "doctor";
  static String allDoctors = "all_doctors";
  static String doctorsByDepartment(id) => "doctor_department/$id";
  static String doctorById(id) => "doctor/$id";
  static String deleteDoctor(id) => "delete_doctor/$id";
  static String doctorSchedule(id) => "doctor_schedule/$id";

  // Appointments
  static String appointments = "appointments"; // GET (list) / POST (book)
  static String updateAppointment(id) =>
      "appointments/$id"; // PUT (reschedule) — بس لو confirmed
  static String rateAppointment(id) =>
      "appointments/$id/rate"; // POST — بس لو completed

  // "appointments_cancel/{id}" مسجل تحت صلاحية secretary فقط.
  // "المريض لا يملك route إلغاء مباشر" — نص صريح من الباك إند.
  static String cancelAppointment(id) => "appointments_cancel/$id";

  // Loyalty Points
  static String points = "points";
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
