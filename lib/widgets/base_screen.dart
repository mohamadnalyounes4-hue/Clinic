import 'package:flutter/material.dart';

/// Base screen class to ensure consistent scaffold structure
/// across all screens in the app
abstract class BaseScreen extends StatelessWidget {
  const BaseScreen({super.key});

  /// App bar to be used in the screen
  PreferredSizeWidget? appBar(BuildContext context) => null;

  /// Body content of the screen
  Widget body(BuildContext context);

  /// Background color of the scaffold
  Color? scaffoldBackgroundColor(BuildContext context) => Colors.white;

  /// Whether to show resize to avoid bottom inset
  bool resizeToAvoidBottomInset() => true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(context),
      backgroundColor: scaffoldBackgroundColor(context),
      resizeToAvoidBottomInset: resizeToAvoidBottomInset(),
      body: body(context),
    );
  }
}
