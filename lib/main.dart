import 'package:flutter/material.dart';

import 'screens/root_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const StipaApp());
}

class StipaApp extends StatelessWidget {
  const StipaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stipa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const RootScreen(),
    );
  }
}
