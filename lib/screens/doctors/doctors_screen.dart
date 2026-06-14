import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Cubits/clinic_states.dart';
import '../../Cubits/doctor_cubit.dart';
import '../../Models/doctor_directory_model.dart';
import '../../Models/doctor_model.dart';
import '../../core/theme/nabd_colors.dart';
import '../../widgets/doctors/doctor_card.dart';
import '../../widgets/doctors/specialty_filter_bar.dart';
import 'booking_detail_screen.dart';
import 'doctor_profile_booking_screen.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  String _selectedCategory = 'All Doctors';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorCubit>().getAllDoctors();
    });
  }

  List<DoctorModel> _filteredDoctors(List<DoctorModel> doctors) {
    return doctors.where((doc) {
      final name = doc.fullName.toLowerCase();
      final specialty = (doc.specialization ?? '').toLowerCase();
      final certificate = (doc.certificate ?? '').toLowerCase();
      final category = _selectedCategory.toLowerCase();
      final query = _searchQuery.toLowerCase();
      final matchesCategory =
          _selectedCategory == 'All Doctors' || specialty.contains(category);
      final matchesSearch =
          _searchQuery.isEmpty ||
          name.contains(query) ||
          specialty.contains(query) ||
          certificate.contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<String> _categoriesFromDoctors(List<DoctorModel> doctors) {
    final specialties =
        doctors
            .map((doctor) => doctor.specialization?.trim())
            .whereType<String>()
            .where((specialty) => specialty.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return ['All Doctors', ...specialties];
  }

  Doctor _bookingDoctorFromModel(DoctorModel doctor) {
    final fullName = doctor.fullName.trim();
    final displayName = fullName.isEmpty ? 'Doctor' : 'Dr. $fullName';
    final specialty = doctor.specialization?.trim();
    final certificate = doctor.certificate?.trim();

    return Doctor(
      id: doctor.id.toString(),
      name: displayName,
      specialty: specialty?.isNotEmpty == true ? specialty! : 'Doctor',
      hospital: certificate?.isNotEmpty == true ? certificate! : 'Nabdh Clinic',
      rating: 4.9,
      price: 250,
      imagePath: doctor.profileImage ?? 'assets/images/Male.jpg',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NabadColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 12),
            _buildFiltersButton(),
            const SizedBox(height: 16),
            BlocBuilder<DoctorCubit, DoctorState>(
              builder: (context, state) {
                final categories = state is DoctorSuccess
                    ? _categoriesFromDoctors(state.doctors)
                    : const ['All Doctors'];

                if (!categories.contains(_selectedCategory)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _selectedCategory = 'All Doctors');
                    }
                  });
                }

                return SpecialtyFilterBar(
                  categories: categories,
                  selectedCategory: _selectedCategory,
                  onSelected: (val) => setState(() => _selectedCategory = val),
                );
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BlocBuilder<DoctorCubit, DoctorState>(
                builder: (context, state) {
                  if (state is DoctorInitial || state is DoctorLoading) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }

                  if (state is DoctorError) {
                    return _buildError(state.message);
                  }

                  if (state is DoctorSuccess) {
                    final doctors = _filteredDoctors(state.doctors);

                    if (doctors.isEmpty) return _buildEmpty();

                    return RefreshIndicator(
                      color: NabadColors.primary,
                      onRefresh: () =>
                          context.read<DoctorCubit>().getAllDoctors(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: doctors.length,
                        itemBuilder: (context, index) {
                          final doctorModel = doctors[index];
                          final doctor = _bookingDoctorFromModel(doctorModel);
                          return DoctorCard(
                            doctor: doctor,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DoctorProfileBookingScreen(
                                    doctor: doctorModel,
                                  ),
                                ),
                              );
                            },
                            onBookNow: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BookingDetailScreen(doctor: doctor),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: NabadColors.softTeal,
                  border: Border.all(
                    color: NabadColors.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: NabadColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Nabdh',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: NabadColors.darkText,
                ),
              ),
            ],
          ),
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: NabadColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: NabadColors.primary.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: NabadColors.darkText,
                  size: 20,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: NabadColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: const TextStyle(fontSize: 14, color: NabadColors.darkText),
        decoration: InputDecoration(
          hintText: 'Search doctors, specialties...',
          hintStyle: const TextStyle(
            color: NabadColors.mutedText,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: NabadColors.mutedText,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: NabadColors.mutedText,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: NabadColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(color: NabadColors.divider, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(50),
            borderSide: const BorderSide(
              color: NabadColors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersButton() {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () => _showFilterSheet(context),
        icon: const Icon(Icons.tune_rounded, size: 16),
        label: const Text('Filters'),
        style: OutlinedButton.styleFrom(
          foregroundColor: NabadColors.darkText,
          side: const BorderSide(color: NabadColors.divider, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: NabadColors.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          const Text(
            'No doctors found',
            style: TextStyle(
              color: NabadColors.mutedText,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 60,
              color: NabadColors.primary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: NabadColors.mutedText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<DoctorCubit>().getAllDoctors(),
              style: ElevatedButton.styleFrom(
                backgroundColor: NabadColors.primary,
                foregroundColor: NabadColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FilterSheet(),
    );
  }
}

// ── Filter Bottom Sheet ──
class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: NabadColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NabadColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Filter Doctors',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: NabadColors.darkText,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Price Range, Rating, Distance filters coming soon.',
            style: TextStyle(color: NabadColors.mutedText, fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: NabadColors.primary,
                foregroundColor: NabadColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Apply',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
