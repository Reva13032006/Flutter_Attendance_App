import 'package:flutter/material.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../services/dashboard_service.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late Future<List<Attendance>> attendanceFuture;

  @override
  void initState() {
    super.initState();
    attendanceFuture = AttendanceService.fetchAttendance();
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
      appBar: AppBar(title: const Text("My Attendance")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // =========================
            // STUDENT DASHBOARD SUMMARY (6)
            // =========================
            FutureBuilder(
              future: DashboardService.fetchStudentDashboard(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                final d = snapshot.data as Map<String, dynamic>;

                final int totalCourses = d["totalCourses"];
                final int totalClasses = d["totalClasses"];
                final int present = d["presentCount"];
                final int absent = totalClasses - present;
                final double percentage = d["percentage"];

                final bool isDefaulter = percentage < 75;

                return Column(
                  children: [
                    Row(
                      children: [
                        summaryCard(
                          "Courses",
                          totalCourses.toString(),
                          Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        summaryCard(
                          "Classes",
                          totalClasses.toString(),
                          Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        summaryCard(
                          "Present",
                          present.toString(),
                          Colors.green,
                        ),
                        const SizedBox(width: 8),
                        summaryCard(
                          "Absent",
                          absent.toString(),
                          Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        summaryCard(
                          "Attendance %",
                          "${percentage.toStringAsFixed(1)}%",
                          percentage >= 75
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        summaryCard(
                          "Status",
                          isDefaulter ? "DEFAULTER" : "SAFE",
                          isDefaulter ? Colors.red : Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            // =========================
            // ATTENDANCE LIST
            // =========================
            Expanded(
              child: FutureBuilder<List<Attendance>>(
                future: attendanceFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text("Error: ${snapshot.error}"));
                  } else {
                    final attendanceList = snapshot.data!;
                    return ListView.builder(
                      itemCount: attendanceList.length,
                      itemBuilder: (context, index) {
                        final attendance = attendanceList[index];
                        return Card(
                          margin: const EdgeInsets.all(10),
                          child: ListTile(
                            title: Text(attendance.courseName),
                            subtitle:
                                Text("Date: ${attendance.date}"),
                            trailing: Text(
                              attendance.status,
                              style: TextStyle(
                                color: attendance.status == "PRESENT"
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}