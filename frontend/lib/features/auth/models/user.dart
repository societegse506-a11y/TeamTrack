class User {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String role;
  final bool isActive;
  final double? lat;
  final double? lng;

  User({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    this.role = 'user',
    this.isActive = true,
    this.lat,
    this.lng,
  });

  bool get isAdmin => role == 'admin';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'] ?? '',
      role: json['role'] ?? 'user',
      isActive: json['isActive'] ?? true,
      lat: json['position']?['lat'],
      lng: json['position']?['lng'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'role': role,
      'isActive': isActive,
    };
  }
}
