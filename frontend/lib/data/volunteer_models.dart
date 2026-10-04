enum ApplicationStatus {
  pending('PENDING', 'Pending'),
  accepted('ACCEPTED', 'Accepted'),
  rejected('REJECTED', 'Rejected');

  const ApplicationStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ApplicationStatus fromApi(String value) => switch (value) {
    'PENDING' => ApplicationStatus.pending,
    'ACCEPTED' => ApplicationStatus.accepted,
    'REJECTED' => ApplicationStatus.rejected,
    _ => throw FormatException('Unknown application status: $value'),
  };
}

class Opportunity {
  const Opportunity({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.status,
    required this.organization,
    this.contactInfo,
    this.organizationBio,
    this.applicationCount,
  });

  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final String status;
  final String organization;
  final String? contactInfo;
  final String? organizationBio;
  final int? applicationCount;

  factory Opportunity.fromJson(Map<String, dynamic> json) {
    final ngo = json['ngo'];
    final date = json['date'];
    final count = json['_count'];
    if (json['id'] is! String ||
        json['title'] is! String ||
        json['location'] is! String ||
        date is! String ||
        json['status'] is! String ||
        (json['description'] != null && json['description'] is! String) ||
        (ngo != null &&
            (ngo is! Map<String, dynamic> || ngo['name'] is! String))) {
      throw const FormatException(
        'The server returned an invalid opportunity.',
      );
    }

    final parsedDate = DateTime.tryParse(date);
    if (parsedDate == null) {
      throw const FormatException('The opportunity has an invalid date.');
    }
    final applicationCount = count is Map<String, dynamic>
        ? count['applications']
        : null;
    if (applicationCount != null && applicationCount is! int) {
      throw const FormatException(
        'The opportunity has an invalid application count.',
      );
    }

    return Opportunity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      location: json['location'] as String,
      date: parsedDate,
      status: json['status'] as String,
      organization: ngo is Map<String, dynamic>
          ? ngo['name'] as String
          : 'Organization',
      contactInfo: ngo is Map<String, dynamic> && ngo['contactInfo'] is String
          ? ngo['contactInfo'] as String
          : null,
      organizationBio: ngo is Map<String, dynamic> && ngo['bio'] is String
          ? ngo['bio'] as String
          : null,
      applicationCount: applicationCount as int?,
    );
  }
}

class VolunteerApplication {
  const VolunteerApplication({
    required this.id,
    required this.status,
    required this.appliedAt,
    required this.opportunity,
  });

  final String id;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final Opportunity opportunity;

  factory VolunteerApplication.fromJson(Map<String, dynamic> json) {
    final opportunity = json['opportunity'];
    final appliedAt = json['appliedAt'];
    if (json['id'] is! String ||
        json['status'] is! String ||
        appliedAt is! String ||
        opportunity is! Map<String, dynamic>) {
      throw const FormatException(
        'The server returned an invalid application.',
      );
    }

    final parsedAppliedAt = DateTime.tryParse(appliedAt);
    if (parsedAppliedAt == null) {
      throw const FormatException('The application has an invalid date.');
    }

    return VolunteerApplication(
      id: json['id'] as String,
      status: ApplicationStatus.fromApi(json['status'] as String),
      appliedAt: parsedAppliedAt,
      opportunity: Opportunity.fromJson(opportunity),
    );
  }
}

Map<String, dynamic> jsonObject(Object? value, String description) {
  if (value is Map<String, dynamic>) return value;
  throw FormatException('The server returned invalid $description data.');
}

List<Map<String, dynamic>> jsonObjectList(Object? value, String description) {
  if (value is! List) {
    throw FormatException('The server returned invalid $description data.');
  }
  return value
      .map((item) => jsonObject(item, description))
      .toList(growable: false);
}
