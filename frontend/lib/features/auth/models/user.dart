class User {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final double? lat;
  final double? lng;

  User({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    this.lat,
    this.lng,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'] ?? '',
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
    };
  }
}
