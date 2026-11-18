import 'dart:convert';

class SoalKuis {
  final int? id;
  final int modulId;
  final String pertanyaan;
  final List<String> opsiJawaban;
  final int kunciJawaban; // Index opsi jawaban yang benar (0-3)

  SoalKuis({
    this.id,
    required this.modulId,
    required this.pertanyaan,
    required this.opsiJawaban,
    required this.kunciJawaban,
  });

  /// Mengonversi object SoalKuis ke format Map untuk SQLite.
  /// `opsiJawaban` diserialisasikan menjadi String JSON.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'modulId': modulId,
      'pertanyaan': pertanyaan,
      'opsiJawaban': jsonEncode(opsiJawaban),
      'kunciJawaban': kunciJawaban,
    };
  }

  /// Membuat object SoalKuis dari Map hasil query SQLite.
  /// Men-decode string JSON pada kolom `opsiJawaban` kembali ke `List<String>`.
  factory SoalKuis.fromMap(Map<String, dynamic> map) {
    List<String> parsedOpsi = [];
    final rawOpsi = map['opsiJawaban'];
    if (rawOpsi is String && rawOpsi.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawOpsi);
        if (decoded is List) {
          parsedOpsi = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        parsedOpsi = [];
      }
    } else if (rawOpsi is List) {
      parsedOpsi = rawOpsi.map((e) => e.toString()).toList();
    }

    return SoalKuis(
      id: map['id'] as int?,
      modulId: map['modulId'] as int? ?? 0,
      pertanyaan: map['pertanyaan'] as String? ?? '',
      opsiJawaban: parsedOpsi,
      kunciJawaban: map['kunciJawaban'] as int? ?? 0,
    );
  }

  SoalKuis copyWith({
    int? id,
    int? modulId,
    String? pertanyaan,
    List<String>? opsiJawaban,
    int? kunciJawaban,
  }) {
    return SoalKuis(
      id: id ?? this.id,
      modulId: modulId ?? this.modulId,
      pertanyaan: pertanyaan ?? this.pertanyaan,
      opsiJawaban: opsiJawaban ?? this.opsiJawaban,
      kunciJawaban: kunciJawaban ?? this.kunciJawaban,
    );
  }

  @override
  String toString() {
    return 'SoalKuis(id: $id, modulId: $modulId, pertanyaan: $pertanyaan, kunciJawaban: $kunciJawaban)';
  }
}
