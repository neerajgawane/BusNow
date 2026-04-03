import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/conductor_home.dart';
import 'screens/passenger_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  final role = prefs.getString('role');

  Widget home = const LoginScreen();
  if (token != null) {
      if (role == 'conductor') home = const ConductorHomeScreen();
      else if (role == 'passenger') home = const PassengerHomeScreen();
  }
  
  runApp(BusNowApp(initialHome: home));
}

class BusNowApp extends StatelessWidget {
  final Widget initialHome;
  const BusNowApp({super.key, required this.initialHome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusNow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: initialHome,
      debugShowCheckedModeBanner: false,
    );
  }
}
