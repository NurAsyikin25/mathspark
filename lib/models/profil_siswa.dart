class ProfilSiswa {
  final int? id;
  final String namaSiswa;
  final int totalXP;
  final DateTime createdAt;

  ProfilSiswa({
    this.id,
    required this.namaSiswa,
    this.totalXP = 0,
    required this.createdAt,
  });

  /// Mengonversi object ProfilSiswa ke format Map untuk SQLite.
  /// `createdAt` disimpan dalam format ISO 8601 string.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'namaSiswa': namaSiswa,
      'totalXP': totalXP,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Membuat object ProfilSiswa dari Map hasil query SQLite.
  factory ProfilSiswa.fromMap(Map<String, dynamic> map) {
    return ProfilSiswa(
      id: map['id'] as int?,
      namaSiswa: map['namaSiswa'] as String? ?? '',
      totalXP: map['totalXP'] as int? ?? 0,
      createdAt: map['createdAt'] != null
          ? (DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  ProfilSiswa copyWith({
    int? id,
    String? namaSiswa,
    int? totalXP,
    DateTime? createdAt,
  }) {
    return ProfilSiswa(
      id: id ?? this.id,
      namaSiswa: namaSiswa ?? this.namaSiswa,
      totalXP: totalXP ?? this.totalXP,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ProfilSiswa(id: $id, namaSiswa: $namaSiswa, totalXP: $totalXP, createdAt: $createdAt)';
  }
}
