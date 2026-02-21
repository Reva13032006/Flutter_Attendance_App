import 'package:flutter/material.dart';
import '../models/defaulter_model.dart';
import '../services/attendance_service.dart';

class TeacherDefaultersScreen extends StatelessWidget {
  final int courseId;

  const TeacherDefaultersScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Defaulters")),
      body: FutureBuilder<List<Defaulter>>(
        future: AttendanceService.fetchDefaulters(courseId),
        builder: (_, s) {
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = s.data!;
          if (list.isEmpty) {
            return const Center(
              child: Text("No defaulters 🎉"),
            );
          }

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final d = list[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(
                    d.rollNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(d.name),
                  trailing: Text(
                    "${d.percentage.toStringAsFixed(1)}%",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}