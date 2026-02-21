import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'teacher_attendance_history_screen.dart';
import '../services/course_service.dart';
import '../services/enrollment_service.dart';
import '../services/attendance_service.dart';
import '../services/dashboard_service.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  DateTime selectedDate = DateTime.now();

  List<Map<String, dynamic>> courses = [];
  List<Map<String, dynamic>> students = [];

  Map<String, bool> attendance = {};

  int? selectedCourseId;

  bool loadingCourses = true;
  bool loadingStudents = false;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    loadCourses();
  }

  // =========================
  // LOAD TEACHER COURSES
  // =========================
  Future<void> loadCourses() async {
    try {
      final data = await CourseService.fetchMyCourses();
      setState(() {
        courses = List<Map<String, dynamic>>.from(data);
        loadingCourses = false;
      });
    } catch (_) {
      loadingCourses = false;
      showError("Failed to load courses");
    }
  }

  // =========================
  // LOAD STUDENTS OF COURSE
  // =========================
  Future<void> loadStudents(int courseId) async {
    setState(() {
      loadingStudents = true;
      students.clear();
      attendance.clear();
    });

    try {
      final data = await EnrollmentService.fetchStudentsByCourse(courseId);

      setState(() {
        students = List<Map<String, dynamic>>.from(data);
        attendance = {for (var s in students) s["rollNumber"] as String: true};
        loadingStudents = false;
      });
    } catch (_) {
      loadingStudents = false;
      showError("Failed to load students");
    }
  }

  // =========================
  // SUBMIT BULK ATTENDANCE
  // =========================
  Future<void> submitAttendance() async {
    if (selectedCourseId == null || students.isEmpty) return;

    setState(() => submitting = true);

    try {
      await AttendanceService.markBulkAttendance(
        courseId: selectedCourseId!,
        date: selectedDate,
        attendance: attendance,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Attendance submitted successfully"),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        attendance.updateAll((key, value) => true);
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Failed to submit attendance"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => submitting = false);
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // =========================
  // DATE PICKER
  // =========================
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  // =========================
  // SUMMARY CARD
  // =========================
  Widget summaryCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Dashboard"),
        backgroundColor: Colors.blue,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.analytics),
            tooltip: "Attendance Analytics",
            onSelected: (value) {
              if (selectedCourseId == null) {
                showError("Select a course first");
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeacherAttendanceHistoryScreen(
                    courseId: selectedCourseId!,
                    mode: value,
                  ),
                ),
              );
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: "DATE",
                child: Text("📅 Specific Date Attendance"),
              ),
              PopupMenuItem(
                value: "ALL",
                child: Text("📊 Till-Date Attendance"),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // =========================
            // DASHBOARD SUMMARY (5)
            // =========================
            FutureBuilder(
              future: DashboardService.fetchTeacherDashboard(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                final d = snapshot.data as Map<String, dynamic>;
                final double avg = d["averageAttendance"] ?? 0;
                final double absent = 100 - avg;

                return Column(
                  children: [
                    Row(
                      children: [
                        summaryCard(
                          "Courses",
                          d["totalCourses"].toString(),
                          Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        summaryCard(
                          "Students",
                          d["totalStudents"].toString(),
                          Colors.deepPurple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        summaryCard(
                          "Classes",
                          d["totalClasses"].toString(),
                          Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        summaryCard(
                          "Present %",
                          "${avg.toStringAsFixed(1)}%",
                          Colors.green,
                        ),
                        const SizedBox(width: 8),
                        summaryCard(
                          "Absent %",
                          "${absent.toStringAsFixed(1)}%",
                          Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            // =========================
            // COURSE DROPDOWN
            // =========================
            loadingCourses
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<int>(
                    value: selectedCourseId,
                    hint: const Text("Select Course"),
                    items: courses.map((course) {
                      final label =
                          "${course["courseCode"]} - ${course["courseName"]}";
                      return DropdownMenuItem<int>(
                        value: course["id"],
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedCourseId = value);
                      loadStudents(value!);
                    },
                  ),

            const SizedBox(height: 16),

            // DATE PICKER
            InkWell(
              onTap: pickDate,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat("yyyy-MM-dd").format(selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.calendar_today),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // STUDENT LIST
            Expanded(
              child: loadingStudents
                  ? const Center(child: CircularProgressIndicator())
                  : students.isEmpty
                      ? const Center(child: Text("No students enrolled"))
                      : ListView.builder(
                          itemCount: students.length,
                          itemBuilder: (_, index) {
                            final s = students[index];
                            final roll = s["rollNumber"] as String;
                            final isPresent = attendance[roll] ?? true;

                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(
                                  roll,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s["name"]),
                                    const SizedBox(height: 4),
                                    Text(
                                      isPresent ? "PRESENT" : "ABSENT",
                                      style: TextStyle(
                                        color: isPresent
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Switch(
                                  value: isPresent,
                                  onChanged: (v) {
                                    setState(() => attendance[roll] = v);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),

            // SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (selectedCourseId == null || students.isEmpty || submitting)
                        ? null
                        : submitAttendance,
                child: submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Submit Attendance"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}