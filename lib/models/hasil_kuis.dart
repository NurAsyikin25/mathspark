import 'dart:convert';

class HasilKuis {
  final int? id;
  final int modulId;
  final int skorTerakhir;
  final Map<int, int> jawabanSiswa; // Map<indexSoal / idSoal, indexJawabanDipilih>
  final String feedbackAI;
  final DateTime dikerjakanAt;

  HasilKuis({
    this.id,
    required this.modulId,
    required this.skorTerakhir,
    required this.jawabanSiswa,
    required this.feedbackAI,
    required this.dikerjakanAt,
  });

  /// Mengonversi object HasilKuis ke format Map untuk SQLite.
  /// `jawabanSiswa` diserialisasikan ke format JSON string.
  /// `dikerjakanAt` disimpan dalam format ISO 8601 string.
  Map<String, dynamic> toMap() {
    // Kunci JSON harus berupa String
    final formattedJawaban = jawabanSiswa.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    return {
      if (id != null) 'id': id,
      'modulId': modulId,
      'skorTerakhir': skorTerakhir,
      'jawabanSiswa': jsonEncode(formattedJawaban),
      'feedbackAI': feedbackAI,
      'dikerjakanAt': dikerjakanAt.toIso8601String(),
    };
  }

  /// Membuat object HasilKuis dari Map hasil query SQLite.
  factory HasilKuis.fromMap(Map<String, dynamic> map) {
    Map<int, int> parsedJawaban = {};
    final rawJawaban = map['jawabanSiswa'];

    if (rawJawaban is String && rawJawaban.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJawaban);
        if (decoded is Map) {
          parsedJawaban = decoded.map(
            (k, v) => MapEntry(int.parse(k.toString()), int.parse(v.toString())),
          );
        }
      } catch (_) {
        parsedJawaban = {};
      }
    } else if (rawJawaban is Map) {
      parsedJawaban = rawJawaban.map(
        (k, v) => MapEntry(int.parse(k.toString()), int.parse(v.toString())),
      );
    }

    return HasilKuis(
      id: map['id'] as int?,
      modulId: map['modulId'] as int? ?? 0,
      skorTerakhir: map['skorTerakhir'] as int? ?? 0,
      jawabanSiswa: parsedJawaban,
      feedbackAI: map['feedbackAI'] as String? ?? '',
      dikerjakanAt: map['dikerjakanAt'] != null
          ? (DateTime.tryParse(map['dikerjakanAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  HasilKuis copyWith({
    int? id,
    int? modulId,
    int? skorTerakhir,
    Map<int, int>? jawabanSiswa,
    String? feedbackAI,
    DateTime? dikerjakanAt,
  }) {
    return HasilKuis(
      id: id ?? this.id,
      modulId: modulId ?? this.modulId,
      skorTerakhir: skorTerakhir ?? this.skorTerakhir,
      jawabanSiswa: jawabanSiswa ?? this.jawabanSiswa,
      feedbackAI: feedbackAI ?? this.feedbackAI,
      dikerjakanAt: dikerjakanAt ?? this.dikerjakanAt,
    );
  }

  @override
  String toString() {
    return 'HasilKuis(id: $id, modulId: $modulId, skorTerakhir: $skorTerakhir, dikerjakanAt: $dikerjakanAt)';
  }
}
