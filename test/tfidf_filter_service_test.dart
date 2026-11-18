import 'package:flutter_test/flutter_test.dart';
import 'package:mathspark/services/tfidf_filter_service.dart';

void main() {
  group('TfidfFilterService Preprocess Tests', () {
    late TfidfFilterService service;

    setUp(() {
      service = TfidfFilterService();
    });

    test('preprocess converts to lowercase', () {
      final tokens = service.preprocess('LOGIKA MATEMATIKA');
      expect(tokens, containsAll(['logika', 'matematika']));
    });

    test('preprocess removes punctuation and special characters via regex', () {
      final tokens = service.preprocess('Matriks: [2, 3], {4, 5}! (Determinan?)');
      expect(tokens, equals(['matriks', '2', '3', '4', '5', 'determinan']));
    });

    test('preprocess removes Indonesian stopwords', () {
      // Stopwords: yang, dan, di, ke, dari, apa, bagaimana, cara, tolong, kak
      final tokens = service.preprocess(
        'Tolong kak bagaimana cara mencari invers dan determinan di matriks yang ada',
      );
      // 'tolong', 'kak', 'bagaimana', 'cara', 'dan', 'di', 'yang' harus dibuang
      expect(tokens, isNot(contains('tolong')));
      expect(tokens, isNot(contains('kak')));
      expect(tokens, isNot(contains('bagaimana')));
      expect(tokens, isNot(contains('cara')));
      expect(tokens, isNot(contains('dan')));
      expect(tokens, isNot(contains('di')));
      expect(tokens, isNot(contains('yang')));
      expect(tokens, containsAll(['mencari', 'invers', 'determinan', 'matriks', 'ada']));
    });

    test('preprocess handles empty and whitespace strings', () {
      expect(service.preprocess(''), isEmpty);
      expect(service.preprocess('   \t\n  '), isEmpty);
    });
  });

  group('TfidfFilterService validateQuery Tests', () {
    late TfidfFilterService service;

    setUp(() {
      service = TfidfFilterService();
    });

    test('accepts relevant queries for all required math topics (score >= 0.3)', () {
      final relevantQueries = [
        'Apa itu logika matematika?',
        'Bagaimana menentukan nilai kebenaran suatu pernyataan?',
        'Tolong jelaskan konsep negasi atau ingkaran kak',
        'Apa perbedaan konjungsi dan disjungsi?',
        'Bagaimana cara membaca tabel kebenaran implikasi?',
        'Cara menyelesaikan persamaan linier satu variabel',
        'Bagaimana mencari nilai determinan matriks ordo 2x2?',
        'Bagaimana rumus mencari invers matriks ordo 3x3?',
        'Tolong jelaskan apa itu fungsi komposisi dan invers fungsi',
        'Cara menghitung limit fungsi aljabar x mendekati nol',
        'Bagaimana menentukan turunan pertama suatu fungsi?',
        'Bagaimana membuat algoritma dan flowchart percabangan?',
      ];

      for (final query in relevantQueries) {
        final hasil = service.validateQuery(query);
        expect(
          hasil.isRelevant,
          isTrue,
          reason: 'Query "$query" harusnya relevan tapi score=${hasil.score}',
        );
        expect(
          hasil.score,
          greaterThanOrEqualTo(0.3),
          reason: 'Query "$query" score harus >= 0.3, dapat ${hasil.score}',
        );
      }
    });

    test('rejects irrelevant/off-topic queries (score < 0.3)', () {
      final irrelevantQueries = [
        'Bagaimana cara memasak rendang daging sapi?',
        'Siapa presiden amerika serikat sekarang?',
        'Rekomendasi film horor terbaik bioskop',
        'Berapa harga tiket pesawat jakarta bali?',
        'Cuaca hari ini cerah atau hujan ya kak?',
      ];

      for (final query in irrelevantQueries) {
        final hasil = service.validateQuery(query);
        expect(
          hasil.isRelevant,
          isFalse,
          reason: 'Query "$query" tidak boleh relevan, score=${hasil.score}',
        );
        expect(hasil.score, lessThan(0.3));
      }
    });

    test('returns score 0.0 and false for queries only containing stopwords or empty', () {
      final hasilEmpty = service.validateQuery('');
      expect(hasilEmpty.isRelevant, isFalse);
      expect(hasilEmpty.score, equals(0.0));

      final hasilStopwords = service.validateQuery('apa bagaimana cara tolong kak dan di ke dari');
      expect(hasilStopwords.isRelevant, isFalse);
      expect(hasilStopwords.score, equals(0.0));
    });

    test('custom threshold parameter works properly', () {
      const query = 'matriks ordo';
      final normalValidation = service.validateQuery(query, threshold: 0.3);
      expect(normalValidation.isRelevant, isTrue);

      // Dengan threshold sangat tinggi di atas skor aktual
      final strictValidation = service.validateQuery(query, threshold: 0.999);
      expect(strictValidation.isRelevant, isFalse);
      expect(strictValidation.score, equals(normalValidation.score));
    });
  });
}
