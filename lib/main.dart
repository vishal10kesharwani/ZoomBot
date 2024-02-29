import 'package:bluetooth/screens/dashboard.dart';
import 'package:bluetooth/screens/homepage.dart';
import 'package:bluetooth/screens/splash_screen.dart';
import 'package:bluetooth/utils/string_constants.dart';
import 'package:flutter/material.dart';

void main() => runApp(new MyApp());
final routes = {
  '/home': (BuildContext context) => HomePage(),
  '/dashboard': (BuildContext context) => Dashboard(device: device1),
  '/': (BuildContext context) => SplashScreen(),
};

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      title: appName,
      routes: routes,
    );
  }
}
