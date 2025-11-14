import 'package:flutter/material.dart';

import '../screens/home_screen/home_screen.dart';
import '../screens/splash_screen/splash_screen.dart';

class AppRoutes {
  static const String splash = "/";
  static const String homeScreen = "/homeScreen";

  static Map<String, Widget Function(BuildContext)> appRoutes = {
    splash: (context) => const SplashScreen(),
    homeScreen: (context) => const HomeScreen(),
  };
}
