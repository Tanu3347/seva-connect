class VolunteerProfile {
  const VolunteerProfile({
    required this.id,
    required this.email,
    required this.name,
    this.bio,
    this.location,
    this.interests = const [],
    this.skills = const [],
  });

  final String id;
  final String email;
  final String name;
  final String? bio;
  final String? location;
  final List<String> interests;
  final List<String> skills;

  factory VolunteerProfile.fromJson(Map<String, dynamic> json) {
    final interests = json['interests'];
    final skills = json['skills'];
    if (json['id'] is! String ||
        json['email'] is! String ||
        json['name'] is! String ||
        (json['bio'] != null && json['bio'] is! String) ||
        (json['location'] != null && json['location'] is! String) ||
        interests is! List ||
        interests.any((item) => item is! String) ||
        skills is! List ||
        skills.any((item) => item is! String)) {
      throw const FormatException('The server returned an invalid profile.');
    }

    return VolunteerProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      interests: List.unmodifiable(interests.cast<String>()),
      skills: List.unmodifiable(skills.cast<String>()),
    );
  }
}
