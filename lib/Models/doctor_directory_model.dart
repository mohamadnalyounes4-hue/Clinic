class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String hospital;
  final double rating;
  final double price;
  final String imagePath; // محلي أو رابط شبكة
  bool isFavorite;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.hospital,
    required this.rating,
    required this.price,
    required this.imagePath,
    this.isFavorite = false,
  });
}

// بيانات تجريبية - استبدلها بـ API لاحقاً
List<Doctor> sampleDoctors = [
  Doctor(
    id: '1',
    name: 'Dr. Sarah Jenkins',
    specialty: 'Senior Cardiologist',
    hospital: 'Central Medical Hospital',
    rating: 4.9,
    price: 120,
    imagePath: 'assets/images/Male.jpg',
  ),
  Doctor(
    id: '2',
    name: 'Dr. Michael Chen',
    specialty: 'Child Health Specialist',
    hospital: 'Nabdh Wellness Center',
    rating: 4.8,
    price: 100,
    imagePath: 'assets/images/Female.jpg',
  ),
  Doctor(
    id: '3',
    name: 'Dr. Amira Yusuf',
    specialty: 'Dermatologist',
    hospital: 'Skin Care Institute',
    rating: 5.0,
    price: 150,
    imagePath: 'assets/images/3.jpg',
  ),
  Doctor(
    id: '4',
    name: 'Dr. Robert Wilson',
    specialty: 'Neurologist',
    hospital: 'Brain Health Center',
    rating: 4.7,
    price: 180,
    imagePath: 'assets/images/4.jpg',
  ),
  Doctor(
    id: '5',
    name: 'Dr. Layla Hassan',
    specialty: 'Pediatrician',
    hospital: 'Children\'s Care Clinic',
    rating: 4.8,
    price: 90,
    imagePath: 'assets/images/5.jpg',
  ),
];

const List<String> specialtyCategories = [
  'All Doctors',
  'Cardiologist',
  'Pediatrician',
  'Dermatologist',
  'Neurologist',
];
