import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_summary.dart';
import '../services/attendance_service.dart';

class TeacherMonthlySummaryScreen extends StatefulWidget {
  final int courseId;

  const TeacherMonthlySummaryScreen({super.key, required this.courseId});

  @override
  State<TeacherMonthlySummaryScreen> createState() =>
      _TeacherMonthlySummaryScreenState();
}

class _TeacherMonthlySummaryScreenState
    extends State<TeacherMonthlySummaryScreen> {
  DateTime selectedMonth = DateTime.now();
  List<AttendanceSummary> summary = [];
  bool loading = false;

  Future<void> loadSummary() async {
    setState(() => loading = true);

    final month = DateFormat("yyyy-MM").format(selectedMonth);
    final data = await AttendanceService.fetchMonthlySummary(
      widget.courseId,
      month,
    );

    setState(() {
      summary = data;
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Monthly Attendance")),
      body: Column(
        children: [
          TextButton.icon(
            icon: const Icon(Icons.calendar_month),
            label: Text(DateFormat("MMMM yyyy").format(selectedMonth)),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedMonth,
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                selectedMonth = DateTime(picked.year, picked.month);
                loadSummary();
              }
            },
          ),

          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: summary.length,
                    itemBuilder: (_, i) {
                      final s = summary[i];
                      return Card(
                        child: ListTile(
                          title: Text(s.rollNumber),
                          subtitle: Text(
                            "${s.name}\nPresent: ${s.present}/${s.total}",
                          ),
                          trailing: Text(
                            "${s.percentage.toInt()}%",
                            style: TextStyle(
                              color: s.percentage < 75
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}