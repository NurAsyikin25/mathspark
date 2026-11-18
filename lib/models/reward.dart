class Reward {
  final int? id;
  final String namaBadge;
  final String deskripsi;
  final String kondisi;
  final bool sudahDapat;

  Reward({
    this.id,
    required this.namaBadge,
    required this.deskripsi,
    required this.kondisi,
    this.sudahDapat = false,
  });

  /// Mengonversi object Reward ke format Map untuk SQLite.
  /// `sudahDapat` disimpan sebagai integer (1 untuk true, 0 untuk false).
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'namaBadge': namaBadge,
      'deskripsi': deskripsi,
      'kondisi': kondisi,
      'sudahDapat': sudahDapat ? 1 : 0,
    };
  }

  /// Membuat object Reward dari Map hasil query SQLite.
  factory Reward.fromMap(Map<String, dynamic> map) {
    return Reward(
      id: map['id'] as int?,
      namaBadge: map['namaBadge'] as String? ?? '',
      deskripsi: map['deskripsi'] as String? ?? '',
      kondisi: map['kondisi'] as String? ?? '',
      sudahDapat: (map['sudahDapat'] as int? ?? 0) == 1,
    );
  }

  Reward copyWith({
    int? id,
    String? namaBadge,
    String? deskripsi,
    String? kondisi,
    bool? sudahDapat,
  }) {
    return Reward(
      id: id ?? this.id,
      namaBadge: namaBadge ?? this.namaBadge,
      deskripsi: deskripsi ?? this.deskripsi,
      kondisi: kondisi ?? this.kondisi,
      sudahDapat: sudahDapat ?? this.sudahDapat,
    );
  }

  @override
  String toString() {
    return 'Reward(id: $id, namaBadge: $namaBadge, sudahDapat: $sudahDapat, kondisi: $kondisi)';
  }
}
