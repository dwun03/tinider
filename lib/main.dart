import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart'; //unused import for now

void main() {
  runApp(const TiniderApp());
}

class TiniderApp extends StatelessWidget {
  const TiniderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tinider',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/swipe': (context) => const SwipeScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tinider: Select Gate & Budget')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Start Swiping'),
          onPressed: () => Navigator.pushNamed(context, '/swipe'),
        ),
      ),
    );
  }
}

class SwipeScreen extends StatelessWidget {
  const SwipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tinider: Swipe for Food')),
      body: const Center(child: Text('Card swiper will go here')),
    );
  }
}