class User {
  final String id;
  final String username;
  final String role;
  final String? fullName;
  final String? specialization;
  final String? photo;
  final String? experienceYears;
  final String? qualification;
  final String? phoneNumber;
  final String? availableDays;
  final String? gender;
  final String hospitalName;

  User({
    required this.id,
    required this.username,
    required this.role,
    this.fullName,
    this.specialization,
    this.photo,
    this.experienceYears,
    this.qualification,
    this.phoneNumber,
    this.availableDays,
    this.gender,
    this.hospitalName = "GM Hospital",
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      username: json['username'],
      role: json['role'],
      fullName: json['full_name'],
      specialization: json['specialization'],
      photo: json['photo'],
      experienceYears: json['experience_years']?.toString(),
      qualification: json['qualification'],
      phoneNumber: json['mobile_number'],
      availableDays: json['available_days'],
      gender: json['gender'],
    );
  }
}
