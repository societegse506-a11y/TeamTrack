class Member {
  final String id;
  final String nom;
  final String prenom;
  final String cin;
  final String telephone;
  final String description;

  Member({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.cin,
    required this.telephone,
    this.description = '',
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['_id'] ?? json['id'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      cin: json['cin'] ?? '',
      telephone: json['telephone'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'prenom': prenom,
      'cin': cin,
      'telephone': telephone,
      'description': description,
    };
  }

  String get fullName => '$prenom $nom';

  String get initials {
    final p = prenom.isNotEmpty ? prenom[0] : '';
    final n = nom.isNotEmpty ? nom[0] : '';
    return '$p$n'.toUpperCase();
  }
}
