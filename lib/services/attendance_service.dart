import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/defaulter_model.dart';
import '../models/attendance_model.dart';
import '../models/attendance_summary.dart';

class AttendanceService {
  static const String baseUrl = "http://localhost:8081";

  // =================================================
  // 🎓 STUDENT — VIEW OWN ATTENDANCE
  // =================================================
  static Future<List<Attendance>> fetchAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt");

    if (token == null) {
      throw Exception("JWT Token not found. Please login again.");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/api/attendance/student/me"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Attendance.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load attendance (${response.statusCode})");
    }
  }

  // =================================================
  // 👨‍🏫 TEACHER — BULK ATTENDANCE
  // =================================================
  static Future<void> markBulkAttendance({
    required int courseId,
    required DateTime date,
    required Map<String, bool> attendance,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt");

    if (token == null) {
      throw Exception("JWT Token not found. Please login again.");
    }

    final body = {
      "courseId": courseId,
      "date": date.toIso8601String().split("T")[0],
      "records": attendance.entries.map((e) {
        return {
          "rollNumber": e.key,
          "status": e.value ? "PRESENT" : "ABSENT",
        };
      }).toList(),
    };

    final response = await http.post(
      Uri.parse("$baseUrl/api/attendance/mark/bulk"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Attendance submission failed (${response.statusCode})");
    }
  }

  // =================================================
  // 👨‍🏫 TEACHER — COURSE + DATE
  // =================================================
  static Future<List<Attendance>> fetchAttendanceByCourseAndDate(
    int courseId,
    String date,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt");

    if (token == null) throw Exception("JWT missing");

    final response = await http.get(
      Uri.parse("$baseUrl/api/attendance/course/$courseId/date/$date"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Attendance.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load attendance (${response.statusCode})");
    }
  }

  // =================================================
  // 👨‍🏫 TEACHER — TILL DATE (ALL CLASSES)
  // =================================================
  static Future<List<Attendance>> fetchAllAttendanceByCourse(
    int courseId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt");

    if (token == null) throw Exception("JWT missing");

    final response = await http.get(
      Uri.parse("$baseUrl/api/attendance/course/$courseId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Attendance.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load attendance (${response.statusCode})");
    }
  }

  // =================================================
  // 📊 TEACHER — STUDENT-WISE SUMMARY
  // =================================================
  static Future<List<AttendanceSummary>> fetchCourseSummary(
    int courseId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt");

    if (token == null) throw Exception("JWT missing");

    final response = await http.get(
      Uri.parse("$baseUrl/api/attendance/course/$courseId/summary"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => AttendanceSummary.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load summary (${response.statusCode})");
    }
  }

  static Future<List<AttendanceSummary>> fetchMonthlySummary(
    int courseId,
    String month, // yyyy-MM
) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("jwt");

  final response = await http.get(
    Uri.parse("$baseUrl/api/attendance/course/$courseId/month/$month"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map((e) => AttendanceSummary.fromJson(e)).toList();
  } else {
    throw Exception("Failed to load monthly summary");
  }
}

  static Future<bool> isAttendanceAlreadyMarked(
  int courseId,
  DateTime date,
) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("jwt");
  if (token == null) throw Exception("JWT missing");

  final dateStr = date.toIso8601String().split("T")[0];

  final res = await http.get(
    Uri.parse(
      "$baseUrl/api/attendance/course/$courseId/date/$dateStr",
    ),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  if (res.statusCode == 200) {
    final List data = jsonDecode(res.body);
    return data.isNotEmpty; // 🔑 THIS is the lock logic
  } else {
    throw Exception("Failed to check attendance");
  }
}

  // =========================
// 👨‍🏫 COURSE DEFAULTERS
// =========================
static Future<List<Defaulter>> fetchDefaulters(
  int courseId, {
  double threshold = 75,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("jwt")!;

  final res = await http.get(
    Uri.parse(
      "$baseUrl/api/attendance/course/$courseId/defaulters"
      "?threshold=$threshold",
    ),
    headers: {"Authorization": "Bearer $token"},
  );

  final List data = json.decode(res.body);
  return data.map((e) => Defaulter.fromJson(e)).toList();
}

  // =================================================
  // 📄 TEACHER — PAGINATION (LARGE CLASSES)
  // =================================================
  static Future<List<Attendance>> fetchAttendancePaged(
    int courseId,
    int page,
    int size,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt");

    if (token == null) throw Exception("JWT missing");

    final response = await http.get(
      Uri.parse(
        "$baseUrl/api/attendance/course/$courseId/paged?page=$page&size=$size",
      ),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List content = data["content"];
      return content.map((e) => Attendance.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load paged attendance (${response.statusCode})");
    }
  }
}
