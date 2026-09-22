import 'package:flutter/material.dart';

/// The app's root widget. This plan replaces its body with the real
/// composition root and home screen in Task 15; for now it only proves the
/// project scaffold, dependencies, and test harness are wired correctly.
class NovaApp extends StatelessWidget {
  const NovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Nova')),
      ),
    );
  }
}
