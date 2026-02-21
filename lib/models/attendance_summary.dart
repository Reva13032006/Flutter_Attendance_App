class AttendanceSummary {
  final String rollNumber;
  final String name;
  final int present;
  final int total;
  final double percentage;

  AttendanceSummary({
    required this.rollNumber,
    required this.name,
    required this.present,
    required this.total,
    required this.percentage,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      rollNumber: json["rollNumber"],
      name: json["name"],
      present: json["present"],
      total: json["total"],
      percentage: (json["percentage"] as num).toDouble(),
    );
  }
}
