class Attendance {
  final String courseName;
  final String date;
  final String status;

  Attendance({
    required this.courseName,
    required this.date,
    required this.status,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      courseName: json["enrollment"]["course"]["courseName"],
      date: json["date"],
      status: json["status"],
    );
  }
}
