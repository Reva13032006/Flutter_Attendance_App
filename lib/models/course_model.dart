class Course {
  final int id;
  final String courseName;
  final String courseCode;

  Course({
    required this.id,
    required this.courseName,
    required this.courseCode,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      courseName: json['courseName'],
      courseCode: json['courseCode'],
    );
  }
}
