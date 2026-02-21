import 'package:flutter/material.dart';

import '../services/course_service.dart';
import '../services/attendance_service.dart';
import '../models/attendance_summary.dart';

class TeacherAttendanceSummaryScreen extends StatefulWidget {
  const TeacherAttendanceSummaryScreen({super.key});

  @override
  State<TeacherAttendanceSummaryScreen> createState() =>
      _TeacherAttendanceSummaryScreenState();
}

class _TeacherAttendanceSummaryScreenState
    extends State<TeacherAttendanceSummaryScreen> {
  int? selectedCourseId;
  List<Map<String, dynamic>> courses = [];
  List<AttendanceSummary> summary = [];

  bool loadingCourses = true;
  bool loadingSummary = false;

  @override
  void initState() {
    super.initState();
    loadCourses();
  }

  Future<void> loadCourses() async {
    try {
      final data = await CourseService.fetchMyCourses();
      setState(() {
        courses = List<Map<String, dynamic>>.from(data);
        loadingCourses = false;
      });
    } catch (_) {
      showError("Failed to load courses");
    }
  }

  Future<void> loadSummary(int courseId) async {
    setState(() {
      loadingSummary = true;
      summary.clear();
    });

    try {
      final data = await AttendanceService.fetchCourseSummary(courseId);

      setState(() {
        summary = data;
        loadingSummary = false;
      });
    } catch (_) {
      loadingSummary = false;
      showError("Failed to load attendance summary");
    }
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Attendance Summary"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// COURSE DROPDOWN
            loadingCourses
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<int>(
                    hint: const Text("Select Course"),
                    value: selectedCourseId,
                    items: courses.map((c) {
                      return DropdownMenuItem<int>(
                        value: c["id"],
                        child: Text("${c["courseCode"]} - ${c["courseName"]}"),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedCourseId = value);
                      loadSummary(value!);
                    },
                  ),

            const SizedBox(height: 16),

            /// SUMMARY LIST
            Expanded(
              child: loadingSummary
                  ? const Center(child: CircularProgressIndicator())
                  : summary.isEmpty
                  ? const Center(child: Text("No attendance data"))
                  : ListView.builder(
                      itemCount: summary.length,
                      itemBuilder: (_, index) {
                        final s = summary[index];

                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: s.percentage >= 75
                                  ? Colors.green
                                  : Colors.red,
                              child: Text(
                                "${s.percentage.toInt()}%",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            title: Text(
                              s.rollNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "${s.name}\n"
                              "Present: ${s.present} / ${s.total}",
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
