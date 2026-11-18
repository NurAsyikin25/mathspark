class Modul {
  final int? id;
  final String judul;
  final String deskripsi;
  final bool isLocked;
  final String kontenJson;
  final int urutan;

  Modul({
    this.id,
    required this.judul,
    required this.deskripsi,
    this.isLocked = true,
    required this.kontenJson,
    required this.urutan,
  });

  /// Mengonversi object Modul ke format Map untuk penyimpanan SQLite.
  /// Boolean `isLocked` disimpan sebagai integer (1 untuk true, 0 untuk false).
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'judul': judul,
      'deskripsi': deskripsi,
      'isLocked': isLocked ? 1 : 0,
      'kontenJson': kontenJson,
      'urutan': urutan,
    };
  }

  /// Membuat object Modul dari Map hasil query SQLite.
  factory Modul.fromMap(Map<String, dynamic> map) {
    return Modul(
      id: map['id'] as int?,
      judul: map['judul'] as String? ?? '',
      deskripsi: map['deskripsi'] as String? ?? '',
      isLocked: (map['isLocked'] as int? ?? 1) == 1,
      kontenJson: map['kontenJson'] as String? ?? '',
      urutan: map['urutan'] as int? ?? 0,
    );
  }

  Modul copyWith({
    int? id,
    String? judul,
    String? deskripsi,
    bool? isLocked,
    String? kontenJson,
    int? urutan,
  }) {
    return Modul(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      deskripsi: deskripsi ?? this.deskripsi,
      isLocked: isLocked ?? this.isLocked,
      kontenJson: kontenJson ?? this.kontenJson,
      urutan: urutan ?? this.urutan,
    );
  }

  @override
  String toString() {
    return 'Modul(id: $id, judul: $judul, isLocked: $isLocked, urutan: $urutan)';
  }
}
