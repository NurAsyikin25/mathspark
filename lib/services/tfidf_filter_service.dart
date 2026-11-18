import 'dart:math' as math;

/// Model hasil validasi relevansi pertanyaan terhadap korpus istilah matematika.
class ValidasiHasil {
  final bool isRelevant;
  final double score;

  const ValidasiHasil({
    required this.isRelevant,
    required this.score,
  });

  @override
  String toString() =>
      'ValidasiHasil(isRelevant: $isRelevant, score: ${score.toStringAsFixed(4)})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidasiHasil &&
          runtimeType == other.runtimeType &&
          isRelevant == other.isRelevant &&
          score == other.score;

  @override
  int get hashCode => isRelevant.hashCode ^ score.hashCode;
}

/// Service untuk memfilter pertanyaan siswa menggunakan metode TF-IDF
/// dan Cosine Similarity sebelum dikirim ke Gemini API.
class TfidfFilterService {
  /// Stopword umum bahasa Indonesia yang difilter.
  static const Set<String> defaultStopwords = {
    'yang',
    'dan',
    'di',
    'ke',
    'dari',
    'apa',
    'bagaimana',
    'cara',
    'tolong',
    'kak',
  };

  /// Korpus dokumen istilah Matematika SMK (Logika Matematika, Pernyataan, Negasi,
  /// Konjungsi, Disjungsi, Implikasi, Tabel Kebenaran, Persamaan Linier, Variabel,
  /// Matriks, Determinan, Invers, Ordo, Fungsi, Limit, Turunan, Algoritma).
  static const List<String> defaultCorpus = [
    // Topik kontekstual materi Matematika SMK
    'Logika Matematika pernyataan kalimat terbuka tertutup proposisi nilai kebenaran premis argumen logika matematika',
    'Pernyataan kalimat deklaratif tertutup terbuka proposisi nilai kebenaran benar salah premis konklusi',
    'Negasi ingkaran pernyataan logika ingkaran penyangkalan bukan tidak benar simbol tilde tabel kebenaran',
    'Konjungsi pernyataan majemuk kata hubung dan simbol konjungsi bernilai benar jika kedua pernyataan bernilai benar',
    'Disjungsi pernyataan majemuk kata hubung atau simbol disjungsi bernilai salah jika kedua pernyataan bernilai salah',
    'Implikasi biimplikasi pernyataan bersyarat jika maka jika dan hanya jika anteseden konsekuen syarat cukup syarat perlu',
    'Tabel Kebenaran evaluasi nilai benar salah tabel kebenaran logika matematika proposisi tautologi kontradiksi kontingensi',
    'Persamaan Linier sistem persamaan linear satu variabel dua variabel spldv spltv eliminasi substitusi grafik himpunan penyelesaian',
    'Variabel koefisien konstanta suku persamaan pertidaksamaan linear aljabar nilai variabel x y z penyelesaian',
    'Matriks ordo baris kolom elemen matriks operasi penjumlahan pengurangan perkalian skalar perkalian matriks transpose matriks',
    'Determinan determinan matriks ordo dua ordo tiga aturan sarrus minor kofaktor ekspansi baris kolom matriks singular',
    'Invers invers matriks adjoin determinan matriks persegi rumus invers matriks solusi persamaan matriks',
    'Ordo ordo matriks ukuran baris kali kolom dimensi matriks ordo 2x2 ordo 3x3 ordo mxn',
    'Fungsi relasi pemetaan domain daerah asal kodomain range fungsi linear fungsi kuadrat fungsi komposisi invers grafik fungsi',
    'Limit limit fungsi aljabar x mendekati nilai tak hingga bentuk tentu tak tentu faktorisasi dalil l hopital kontinuitas',
    'Turunan fungsi diferensial turunan pertama gradien garis singgung nilai stasioner maksimum minimum laju perubahan aplikasi turunan',
    'Algoritma pemrograman logika komputasi pseudocode flowchart struktur kontrol percabangan perulangan looping matematika pplg',

    // Dokumen istilah kunci spesifik
    'Logika Matematika',
    'Pernyataan',
    'Negasi',
    'Konjungsi',
    'Disjungsi',
    'Implikasi',
    'Tabel Kebenaran',
    'Persamaan Linier',
    'Variabel',
    'Matriks',
    'Determinan',
    'Invers',
    'Ordo',
    'Fungsi',
    'Limit',
    'Turunan',
    'Algoritma',
  ];

  final List<String> _corpus;
  final Set<String> _stopwords;

  // IDF untuk setiap token unik di korpus
  final Map<String, double> _idfMap = {};

  // Vektor TF-IDF dokumen korpus dan magnitude-nya
  final List<Map<String, double>> _corpusVectors = [];
  final List<double> _corpusMagnitudes = [];

  TfidfFilterService({
    List<String>? corpus,
    Set<String>? stopwords,
  })  : _corpus = corpus ?? defaultCorpus,
        _stopwords = stopwords ?? defaultStopwords {
    _initializeCorpus();
  }

  /// Corpus yang digunakan saat ini (read-only)
  List<String> get corpus => List.unmodifiable(_corpus);

  /// Stopwords yang digunakan saat ini (read-only)
  Set<String> get stopwords => Set.unmodifiable(_stopwords);

  /// Tokenisasi dan pembersihan teks:
  /// 1. Lowercase
  /// 2. Hapus tanda baca / karakter khusus via Regex
  /// 3. Tokenisasi per spasi
  /// 4. Hapus stopword umum Bahasa Indonesia (yang, dan, di, ke, dari, apa, bagaimana, cara, tolong, kak)
  List<String> preprocess(String text) {
    if (text.trim().isEmpty) return [];

    // Lowercase
    final lower = text.toLowerCase();

    // Hapus tanda baca/karakter khusus via Regex (hanya mempertahankan huruf, angka, dan spasi)
    final cleaned = lower.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');

    // Tokenisasi per spasi
    final tokens = cleaned
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty);

    // Filter stopword umum
    return tokens.where((token) => !_stopwords.contains(token)).toList();
  }

  /// Inisialisasi: hitung IDF korpus dan bentuk vektor dokumen korpus.
  void _initializeCorpus() {
    final docTokensList = <List<String>>[];

    // Preprocess semua dokumen dalam korpus
    for (final doc in _corpus) {
      docTokensList.add(preprocess(doc));
    }

    final totalDocs = docTokensList.length;
    if (totalDocs == 0) return;

    // Hitung Document Frequency (DF) untuk setiap term
    final dfMap = <String, int>{};
    for (final tokens in docTokensList) {
      final uniqueTokens = tokens.toSet();
      for (final token in uniqueTokens) {
        dfMap[token] = (dfMap[token] ?? 0) + 1;
      }
    }

    // Hitung IDF sekali saat inisialisasi: ln((1 + N) / (1 + df)) + 1 (Smooth IDF)
    for (final entry in dfMap.entries) {
      final token = entry.key;
      final df = entry.value;
      _idfMap[token] = math.log((1 + totalDocs) / (1 + df)) + 1.0;
    }

    // Bentuk vektor TF-IDF dokumen korpus dan simpan magnitudo-nya
    for (final tokens in docTokensList) {
      final vector = _buildTfIdfVector(tokens);
      final magnitude = _calculateMagnitude(vector);
      _corpusVectors.add(vector);
      _corpusMagnitudes.add(magnitude);
    }
  }

  /// Menghitung vektor TF-IDF dari daftar token.
  Map<String, double> _buildTfIdfVector(List<String> tokens) {
    final vector = <String, double>{};
    if (tokens.isEmpty) return vector;

    // Hitung Term Frequency (TF)
    final tfMap = <String, int>{};
    for (final token in tokens) {
      tfMap[token] = (tfMap[token] ?? 0) + 1;
    }

    final totalTokens = tokens.length;

    // TF * IDF
    for (final entry in tfMap.entries) {
      final term = entry.key;
      final count = entry.value;
      final idf = _idfMap[term] ?? 0.0;
      if (idf > 0) {
        final tf = count / totalTokens;
        vector[term] = tf * idf;
      }
    }

    return vector;
  }

  /// Menghitung magnitude (norm Euclidean) dari vektor TF-IDF.
  double _calculateMagnitude(Map<String, double> vector) {
    var sumSq = 0.0;
    for (final val in vector.values) {
      sumSq += val * val;
    }
    return math.sqrt(sumSq);
  }

  /// Menghitung Cosine Similarity antara dua vektor TF-IDF.
  double _calculateCosineSimilarity(
    Map<String, double> vecA,
    double magA,
    Map<String, double> vecB,
    double magB,
  ) {
    if (magA == 0.0 || magB == 0.0) return 0.0;

    var dotProduct = 0.0;
    // Iterasi pada vektor yang lebih ringkas untuk efisiensi komputasi
    final smallerVec = vecA.length < vecB.length ? vecA : vecB;
    final largerVec = vecA.length < vecB.length ? vecB : vecA;

    for (final entry in smallerVec.entries) {
      final otherVal = largerVec[entry.key];
      if (otherVal != null) {
        dotProduct += entry.value * otherVal;
      }
    }

    final similarity = dotProduct / (magA * magB);
    return similarity.clamp(0.0, 1.0);
  }

  /// Memvalidasi pertanyaan siswa apakah relevan dengan materi Matematika SMK.
  ///
  /// Mengembalikan objek [ValidasiHasil] dengan `isRelevant` (bool)
  /// dan `score` (double) maksimum Cosine Similarity terhadap korpus dokumen.
  ValidasiHasil validateQuery(String query, {double threshold = 0.3}) {
    final queryTokens = preprocess(query);
    if (queryTokens.isEmpty) {
      return const ValidasiHasil(isRelevant: false, score: 0.0);
    }

    final queryVector = _buildTfIdfVector(queryTokens);
    final queryMagnitude = _calculateMagnitude(queryVector);

    if (queryMagnitude == 0.0) {
      return const ValidasiHasil(isRelevant: false, score: 0.0);
    }

    var maxScore = 0.0;

    for (var i = 0; i < _corpusVectors.length; i++) {
      final docVector = _corpusVectors[i];
      final docMagnitude = _corpusMagnitudes[i];

      final similarity = _calculateCosineSimilarity(
        queryVector,
        queryMagnitude,
        docVector,
        docMagnitude,
      );

      if (similarity > maxScore) {
        maxScore = similarity;
      }
    }

    final isRelevant = maxScore >= threshold;
    return ValidasiHasil(isRelevant: isRelevant, score: maxScore);
  }
}
