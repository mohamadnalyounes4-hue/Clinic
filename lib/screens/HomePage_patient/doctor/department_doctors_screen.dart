import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nabad/Cubits/cubits/doctor_cubit.dart';
import 'package:nabad/Cubits/states/clinic_states.dart';
import 'package:nabad/Models/department_model.dart';
import 'package:nabad/Models/doctor_model.dart';
import 'package:nabad/core/theme/nabd_colors.dart';
import 'package:nabad/core/localization/app_localizations.dart';
import 'package:nabad/screens/HomePage_patient/doctor/doctor_profile_booking_screen.dart';
import 'package:nabad/widgets/doctors/patient_doctor_card.dart';

class DepartmentDoctorsScreen extends StatefulWidget {
  final DepartmentModel department;

  const DepartmentDoctorsScreen({super.key, required this.department});

  @override
  State<DepartmentDoctorsScreen> createState() =>
      _DepartmentDoctorsScreenState();
}

class _DepartmentDoctorsScreenState extends State<DepartmentDoctorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DoctorModel> _filteredDoctors(List<DoctorModel> doctors) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return doctors;

    return doctors
        .where((doctor) => doctor.fullName.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _reload() =>
      context.read<DoctorCubit>().getDoctorsByDepartment(widget.department.id);

  void _openDoctor(DoctorModel doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorProfileBookingScreen(doctor: doctor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: context.l10n.isArabic
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            context.tr(widget.department.department_name),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          leading: const BackButton(),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                child: _DepartmentSearchBox(
                  controller: _searchController,
                  query: _searchQuery,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              ),
              Expanded(
                child: BlocBuilder<DoctorCubit, DoctorState>(
                  builder: (context, state) {
                    if (state is DoctorInitial || state is DoctorLoading) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }

                    if (state is DoctorError) {
                      return _DepartmentError(
                        message: state.message,
                        onRetry: _reload,
                      );
                    }

                    if (state is DoctorSuccess) {
                      final doctors = _filteredDoctors(state.doctors);
                      if (doctors.isEmpty) {
                        return _DepartmentEmpty(
                          hasSearch: _searchQuery.isNotEmpty,
                        );
                      }

                      return RefreshIndicator(
                        color: NabadColors.primary,
                        onRefresh: _reload,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          itemCount: doctors.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, index) => PatientDoctorCard(
                            doctor: doctors[index],
                            onTap: () => _openDoctor(doctors[index]),
                          ),
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
      ),
    );
  }
}

class _DepartmentSearchBox extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _DepartmentSearchBox({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      decoration: InputDecoration(
        hintText: context.tr('ابحث عن طبيب بالاسم...'),
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: NabadColors.primary.withAlpha(18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: NabadColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _DepartmentEmpty extends StatelessWidget {
  final bool hasSearch;

  const _DepartmentEmpty({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          context.tr(
            hasSearch
                ? 'لا يوجد طبيب بهذا الاسم ضمن الاختصاص.'
                : 'لا يوجد أطباء ضمن هذا الاختصاص حالياً.',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: NabadColors.mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DepartmentError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DepartmentError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.tr(message),
              textAlign: TextAlign.center,
              style: const TextStyle(color: NabadColors.mutedText),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr('إعادة المحاولة')),
            ),
          ],
        ),
      ),
    );
  }
}
