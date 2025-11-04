import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    // Small delay to ensure Lottie is loaded
    await Future.delayed(const Duration(milliseconds: 100));

    // Remove native splash after Lottie is ready
    FlutterNativeSplash.remove();

    // Wait for animation to complete
    await Future.delayed(const Duration(seconds: 5));

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Lottie.asset(
          'assets/animations/cinema.json',
          width: 300,
          height: 300,
          fit: BoxFit.contain,
          // Optional: callback when animation loads
          onLoaded: (composition) {
            // Animation is loaded
            print('Lottie animation loaded');
          },
        ),
      ),
    );
  }
}