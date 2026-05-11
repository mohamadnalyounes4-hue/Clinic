import 'package:flutter/material.dart';

/// Base class for all custom widgets to ensure consistency
/// and reduce code duplication through inheritance
abstract class BaseWidget extends StatelessWidget {
  const BaseWidget({super.key});

  @override
  Widget build(BuildContext context);
}
