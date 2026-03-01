class UserProfile {
  final String basicInfo;
  final String detailedInfo;
  final int? passingScore;

  const UserProfile({
    this.basicInfo = '',
    this.detailedInfo = '',
    this.passingScore,
  });

  Map<String, dynamic> toJson() => {
        'basicInfo': basicInfo,
        'detailedInfo': detailedInfo,
        'passingScore': passingScore,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        basicInfo: json['basicInfo'] as String? ?? '',
        detailedInfo: json['detailedInfo'] as String? ?? '',
        passingScore: json['passingScore'] as int?,
      );
}
