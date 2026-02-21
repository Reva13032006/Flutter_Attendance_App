class Defaulter {
  final String rollNumber;
  final String name;
  final double percentage;

  Defaulter({
    required this.rollNumber,
    required this.name,
    required this.percentage,
  });

  factory Defaulter.fromJson(Map<String, dynamic> json) {
    return Defaulter(
      rollNumber: json["rollNumber"],
      name: json["name"],
      percentage: (json["percentage"] as num).toDouble(),
    );
  }
}