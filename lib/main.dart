import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart';
import 'splash_screen/splash_screen.dart';
import 'home_screen.dart'; // Your main app screen
import 'movies/homepage.dart';
import 'movies/ratingpage.dart';

Future<void> main() async {
  // Preserve the native splash screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetMatch',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      /*home: const HomePage(),*/
      routes: {
        '/home': (context) => const HomeScreen(),
        '/movies' : (context) =>  HomePage(),
      },
    );
  }
}