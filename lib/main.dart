import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/cart_provider.dart';
import 'screens/root_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const StipaApp());
}

class StipaApp extends StatelessWidget {
  const StipaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Above MaterialApp, so every pushed route sees the same cart.
    return ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        title: 'Stipa',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const RootScreen(),
      ),
    );
  }
}
