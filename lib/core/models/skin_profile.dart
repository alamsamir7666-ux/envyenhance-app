/// Matches the raw `skinProfilesTable` row returned by `GET /skin-profile`
/// (this route returns the DB row directly, not a formatted shape).
class SkinProfile {
  SkinProfile({
    required this.skinType,
    required this.sensitivity,
    required this.concern,
    required this.routinePreference,
    required this.recommendedTags,
    required this.updatedAt,
  });

  factory SkinProfile.fromJson(Map<String, dynamic> json) {
    return SkinProfile(
      skinType: json['skinType'] as String,
      sensitivity: json['sensitivity'] as String,
      concern: json['concern'] as String,
      routinePreference: json['routinePreference'] as String,
      recommendedTags: (json['recommendedTags'] as List?)?.cast<String>() ?? const [],
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String skinType; // dry | oily | combination | normal
  final String sensitivity; // sensitive | normal | acne
  final String concern; // brightening | antiaging | acne | hydration
  final String routinePreference; // minimal | standard | full | any
  final List<String> recommendedTags;
  final DateTime updatedAt;
}

/// The 4 quiz questions, matching exactly what `skinProfile.ts` expects
/// in its POST body (`feel`, `sensitivity`, `concern`, `routine`).
class SkinQuizOption {
  const SkinQuizOption(this.value, this.label);
  final String value;
  final String label;
}

class SkinQuizQuestions {
  SkinQuizQuestions._();

  static const feel = [
    SkinQuizOption('dry', 'Dry'),
    SkinQuizOption('oily', 'Oily'),
    SkinQuizOption('combination', 'Combination'),
    SkinQuizOption('normal', 'Normal'),
  ];

  static const sensitivity = [
    SkinQuizOption('sensitive', 'Sensitive'),
    SkinQuizOption('normal', 'Not particularly sensitive'),
    SkinQuizOption('acne', 'Acne-prone'),
  ];

  static const concern = [
    SkinQuizOption('brightening', 'Brightening & even tone'),
    SkinQuizOption('antiaging', 'Anti-aging & firming'),
    SkinQuizOption('acne', 'Acne & blemishes'),
    SkinQuizOption('hydration', 'Hydration & moisture'),
  ];

  static const routine = [
    SkinQuizOption('minimal', 'Minimal — 2-3 steps'),
    SkinQuizOption('standard', 'Standard — 4-5 steps'),
    SkinQuizOption('full', 'Full routine — layering'),
    SkinQuizOption('any', 'No preference'),
  ];
}
