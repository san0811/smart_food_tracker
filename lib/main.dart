import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'providers/food_provider.dart';
import 'screens/home/home_screen.dart';

void main() {
  runApp(const SmartFoodApp());
}

class SmartFoodApp extends StatelessWidget {
  const SmartFoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FoodProvider()..loadItems(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SmartFood Tracker',
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
