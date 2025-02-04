import 'package:flutter/material.dart';
import 'main.dart';  // Import the main app screen

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 6)); // Splash screen delay
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DialerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255), // Background color of your choice
      body: Center(
        child: Image.asset(
          'assets/icon.png', // App logo
          height: 250,
          width: 250,
        ),
      ),
    );
  }
}
