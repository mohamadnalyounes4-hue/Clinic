import 'package:flutter/material.dart';

/// Base class for all custom stateful widgets to ensure consistency
/// and reduce code duplication through inheritance
abstract class BaseStatefulWidget extends StatefulWidget {
  const BaseStatefulWidget({super.key});

  @override
  BaseStatefulWidgetState createState();
}

/// Base state class for stateful widgets
abstract class BaseStatefulWidgetState<T extends BaseStatefulWidget>
    extends State<T> {
  @override
  Widget build(BuildContext context);
}
