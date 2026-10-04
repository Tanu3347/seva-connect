import 'volunteer_models.dart';

class NgoApplicant {
  const NgoApplicant({
    required this.id,
    required this.name,
    required this.email,
    this.bio,
    this.contactInfo,
  });

  final String id;
  final String name;
  final String email;
  final String? bio;
  final String? contactInfo;

  factory NgoApplicant.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String ||
        json['name'] is! String ||
        json['email'] is! String ||
        (json['bio'] != null && json['bio'] is! String) ||
        (json['contactInfo'] != null && json['contactInfo'] is! String)) {
      throw const FormatException('The server returned invalid applicant data.');
    }

    return NgoApplicant(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      bio: json['bio'] as String?,
      contactInfo: json['contactInfo'] as String?,
    );
  }
}

class NgoApplication {
  const NgoApplication({
    required this.id,
    required this.status,
    required this.appliedAt,
    required this.applicant,
    required this.opportunity,
  });

  final String id;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final NgoApplicant applicant;
  final Opportunity opportunity;

  factory NgoApplication.fromJson(Map<String, dynamic> json) {
    final volunteer = json['volunteer'];
    final opportunity = json['opportunity'];
    final appliedAt = json['appliedAt'];
    if (json['id'] is! String ||
        json['status'] is! String ||
        appliedAt is! String ||
        volunteer is! Map<String, dynamic> ||
        opportunity is! Map<String, dynamic>) {
      throw const FormatException(
        'The server returned invalid application data.',
      );
    }
    final parsedAppliedAt = DateTime.tryParse(appliedAt);
    if (parsedAppliedAt == null) {
      throw const FormatException('The application has an invalid date.');
    }
    return NgoApplication(
      id: json['id'] as String,
      status: ApplicationStatus.fromApi(json['status'] as String),
      appliedAt: parsedAppliedAt,
      applicant: NgoApplicant.fromJson(volunteer),
      opportunity: Opportunity.fromJson(opportunity),
    );
  }
}
