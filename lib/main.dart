import 'package:bluetooth/screens/homepage.dart';
import 'package:bluetooth/screens/splash_screen.dart';
import 'package:bluetooth/utils/string_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

BluetoothDevice device = BluetoothDevice(address: '');

void main() => runApp(new MyApp());
final routes = {
  '/home': (BuildContext context) => HomePage(),
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
