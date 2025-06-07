class User {
  final String id;
  final String nama;
  final String email;
  final String? fotoProfile; // URL
  final String role; // 'HRD' atau 'USER_BIASA'
  final String? linkLinkedIn;
  final DateTime? createdAt; // Opsional, tergantung response backend
  final DateTime? updatedAt; // Opsional

  User({
    required this.id,
    required this.nama,
    required this.email,
    this.fotoProfile,
    required this.role,
    this.linkLinkedIn,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    print("User fromJson ${json}");
    return User(
      id: json['id'] as String,
      nama: json['nama'] as String,
      email: json['email'] as String,
      fotoProfile: json['foto_profile'] != null ? json['foto_profile'] as String? : "",
      role: json['role'] as String, // Pastikan backend mengirim 'HRD' atau 'USER_BIASA'
      linkLinkedIn: json['linkLinkedIn'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'foto_profile': fotoProfile,
      'role': role,
      'linkLinkedIn': linkLinkedIn,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}