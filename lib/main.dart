import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decode/jwt_decode.dart';

import 'login_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/teacher_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("jwt");

  Widget startScreen = const LoginScreen();

  if (token != null) {
    // ✅ Check if token is expired
    if (Jwt.isExpired(token)) {
      // Optional: clear expired token
      await prefs.remove("jwt");
      startScreen = const LoginScreen();
    } else {
      // ✅ Token is valid, now decode it
      Map<String, dynamic> decodedToken = Jwt.parseJwt(token);
      final role = decodedToken["role"];

      if (role == "STUDENT") {
        startScreen = const StudentDashboard();
      } else if (role == "TEACHER") {
        startScreen = const TeacherDashboard();
      }
    }
  }

  runApp(MyApp(startScreen: startScreen));
}


class MyApp extends StatelessWidget {
  final Widget startScreen;

  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attendance App',
      home: startScreen,
    );
  }
}
