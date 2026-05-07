class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.sourceLang,
    required this.targetLang,
    required this.status,
  });

  final String id;
  final String email;
  final String displayName;
  final String sourceLang;
  final String targetLang;
  final String status;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      sourceLang: json['sourceLang'] as String,
      targetLang: json['targetLang'] as String,
      status: json['status'] as String,
    );
  }
}
