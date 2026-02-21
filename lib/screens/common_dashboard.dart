import 'package:flutter/material.dart';
import 'student_dashboard.dart';
import 'teacher_dashboard.dart';

class CommonDashboard extends StatelessWidget {
  final String role;

  const CommonDashboard({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    if (role == "TEACHER") {
      return const TeacherDashboard();
    } else {
      return const StudentDashboard();
    }
  }
}
