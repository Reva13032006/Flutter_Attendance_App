import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/course_model.dart';
import '../../models/student_model.dart';

class TeacherService {
  static const String baseUrl = "http://localhost:8081";

  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt");
    if (token == null) throw Exception("JWT missing");
    return token;
  }

  // ✅ Courses taught by teacher
  static Future<List<Course>> fetchMyCourses() async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/api/courses/teacher/me"),
      headers: {"Authorization": "Bearer $token"},
    );

    final List data = json.decode(res.body);
    return data.map((e) => Course.fromJson(e)).toList();
  }

  // ✅ Students of a course
  static Future<List<Student>> fetchStudents(int courseId) async {
    final token = await _getToken();

    final res = await http.get(
      Uri.parse("$baseUrl/api/enrollments/course/$courseId"),
      headers: {"Authorization": "Bearer $token"},
    );

    final List data = json.decode(res.body);
    return data.map((e) => Student.fromJson(e['student'])).toList();
  }
}
