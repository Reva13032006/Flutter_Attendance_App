import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardService {
  static const baseUrl = "http://localhost:8081";

  static Future<Map<String, dynamic>> fetchTeacherDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt")!;
    final res = await http.get(
      Uri.parse("$baseUrl/api/dashboard/teacher"),
      headers: {"Authorization": "Bearer $token"},
    );
    return json.decode(res.body);
  }

  static Future<Map<String, dynamic>> fetchStudentDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt")!;
    final res = await http.get(
      Uri.parse("$baseUrl/api/dashboard/student"),
      headers: {"Authorization": "Bearer $token"},
    );
    return json.decode(res.body);
  }
}