class Student {
  final String rollNumber;
  final String name;

  Student({required this.rollNumber, required this.name});

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(rollNumber: json['rollNumber'], name: json['name']);
  }
}
