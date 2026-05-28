import 'package:flutter/material.dart';

enum AccountRole { patient, doctor }

class AccountRoleContent {
  final String title;
  final String headline;
  final String subtitle;
  final String action;
  final String image;
  final String routeName;
  final IconData icon;

  const AccountRoleContent({
    required this.title,
    required this.headline,
    required this.subtitle,
    required this.action,
    required this.image,
    required this.routeName,
    required this.icon,
  });
}
