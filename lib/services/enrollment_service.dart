import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EnrollmentService {
  static const String baseUrl = "http://localhost:8081";

  static Future<List<Map<String, dynamic>>> fetchStudentsByCourse(
    int courseId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt");

    if (token == null) {
      throw Exception("JWT not found");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/api/enrollments/course/$courseId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception("Failed to load students");
    }
  }
}
