import 'package:flutter/material.dart';

import 'screens/setup_screens.dart';
import 'theme/tinider_theme.dart';

void main() => runApp(const TiniderApp());

class TiniderApp extends StatelessWidget {
  const TiniderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tinider',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: TiniderColors.cream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: TiniderColors.yellow,
          surface: TiniderColors.cream,
        ),
        fontFamily: 'Arial',
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
