import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'providers/food_provider.dart';
import 'screens/home/main_navigation_screen.dart';

void main() {
  runApp(const FridgiApp());
}

class FridgiApp extends StatelessWidget {
  const FridgiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FoodProvider()..loadItems(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Fridgi',
        theme: AppTheme.darkTheme,
        home: const MainNavigationScreen(),
      ),
    );
  }
}
