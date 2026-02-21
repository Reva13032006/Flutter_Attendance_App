import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import '../services/attendance_service.dart';
import '../models/attendance_model.dart';

class TeacherAttendanceHistoryScreen extends StatefulWidget {
  final int courseId;
  final String mode; // "DATE" or "ALL"

  const TeacherAttendanceHistoryScreen({
    super.key,
    required this.courseId,
    required this.mode,
  });

  @override
  State<TeacherAttendanceHistoryScreen> createState() =>
      _TeacherAttendanceHistoryScreenState();
}

class _TeacherAttendanceHistoryScreenState
    extends State<TeacherAttendanceHistoryScreen> {
  List<Attendance> attendanceList = [];

  DateTime selectedDate = DateTime.now();
  bool loadingAttendance = false;

  @override
  void initState() {
    super.initState();
    widget.mode == "ALL" ? loadAllAttendance() : loadAttendanceByDate();
  }

  // =========================
  // LOAD DATE-WISE ATTENDANCE
  // =========================
  Future<void> loadAttendanceByDate() async {
    setState(() {
      loadingAttendance = true;
      attendanceList.clear();
    });

    try {
      final dateStr = DateFormat("yyyy-MM-dd").format(selectedDate);
      final data = await AttendanceService.fetchAttendanceByCourseAndDate(
        widget.courseId,
        dateStr,
      );

      setState(() {
        attendanceList =
            data;
        loadingAttendance = false;
      });
    } catch (_) {
      loadingAttendance = false;
      showError("Failed to load attendance");
    }
  }

  // =========================
  // LOAD ALL ATTENDANCE
  // =========================
  Future<void> loadAllAttendance() async {
  setState(() {
    loadingAttendance = true;
    attendanceList.clear();
  });

  try {
    final data =
        await AttendanceService.fetchAllAttendanceByCourse(widget.courseId);

    setState(() {
      attendanceList = data; // ✅ FIX — NO fromJson here
      loadingAttendance = false;
    });
  } catch (_) {
    loadingAttendance = false;
    showError("Failed to load attendance");
  }
}


  // =========================
  // GROUP BY DATE (KEY FIX)
  // =========================
  Map<String, List<Attendance>> get groupedByDate {
    final Map<String, List<Attendance>> map = {};

    for (final a in attendanceList) {
      map.putIfAbsent(a.date, () => []);
      map[a.date]!.add(a);
    }

    return map;
  }

  // =========================
  // EXPORT CSV
  // =========================
  Future<void> exportCsv() async {
    final rows = [
      ["Course", "Date", "Status"],
      ...attendanceList.map((a) => [a.courseName, a.date, a.status]),
    ];

    final csvData = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/attendance.csv");

    await file.writeAsString(csvData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("CSV exported to ${file.path}")),
    );
  }

  // =========================
  // EXPORT PDF
  // =========================
  Future<void> exportPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          children: attendanceList
              .map(
                (a) => pw.Text(
                  "${a.courseName} | ${a.date} | ${a.status}",
                ),
              )
              .toList(),
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/attendance.pdf");
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("PDF exported to ${file.path}")),
    );
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // =========================
  // ANALYTICS
  // =========================
  int get totalStudents => attendanceList.length;
  int get presentCount =>
      attendanceList.where((a) => a.status == "PRESENT").length;
  int get absentCount => totalStudents - presentCount;
  double get percentage =>
      totalStudents == 0 ? 0 : (presentCount / totalStudents) * 100;

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == "ALL"
              ? "Attendance History (Till Date)"
              : "Attendance History (Date)",
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Export CSV",
            onPressed: exportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Export PDF",
            onPressed: exportPdf,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // DATE PICKER (ONLY DATE MODE)
            if (widget.mode == "DATE")
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                    loadAttendanceByDate();
                  }
                },
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

            if (!loadingAttendance && attendanceList.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  buildStat("Total", totalStudents, Colors.blue),
                  buildStat("Present", presentCount, Colors.green),
                  buildStat("Absent", absentCount, Colors.red),
                ],
              ),

            const SizedBox(height: 16),

            // =========================
            // KEY FIX: GROUPED LIST
            // =========================
            Expanded(
              child: loadingAttendance
                  ? const Center(child: CircularProgressIndicator())
                  : attendanceList.isEmpty
                      ? const Center(child: Text("No attendance found"))
                      : widget.mode == "ALL"
                          ? ListView(
                              children: groupedByDate.entries.map((entry) {
                                final date = entry.key;
                                final records = entry.value;

                                return ExpansionTile(
                                  title: Text(
                                    date,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Records: ${records.length}",
                                  ),
                                  children: records.map((a) {
                                    return ListTile(
                                      leading:
                                          const Icon(Icons.school_outlined),
                                      title: Text(a.courseName),
                                      trailing: Text(
                                        a.status,
                                        style: TextStyle(
                                          color: a.status == "PRESENT"
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              }).toList(),
                            )
                          : ListView.builder(
                              itemCount: attendanceList.length,
                              itemBuilder: (_, index) {
                                final a = attendanceList[index];
                                return ListTile(
                                  leading: const Icon(Icons.school),
                                  title: Text(a.courseName),
                                  subtitle: Text("Date: ${a.date}"),
                                  trailing: Text(
                                    a.status,
                                    style: TextStyle(
                                      color: a.status == "PRESENT"
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
            ),

            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: presentCount.toDouble(),
                      title: 'Present',
                      color: Colors.green,
                    ),
                    PieChartSectionData(
                      value: absentCount.toDouble(),
                      title: 'Absent',
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label),
      ],
    );
  }
}
