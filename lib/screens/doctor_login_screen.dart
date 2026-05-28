import 'package:flutter/material.dart';

class DoctorLoginScreen extends StatelessWidget {
  const DoctorLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل دخول الطبيب'),
      ),
      body: const Center(
        child: Text('محتوى صفحة تسجيل دخول الطبيب'),
      ),
    );
  }
}
