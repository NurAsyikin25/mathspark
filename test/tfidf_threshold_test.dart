import 'package:flutter_test/flutter_test.dart';
import 'package:mathspark/services/tfidf_filter_service.dart';

void main() {
  group('TF-IDF Threshold Evaluation Tests (Bab III Proposal)', () {
    late TfidfFilterService filterService;

    // 10 Kueri In-Topic (Pertanyaan Matematika SMK)
    final inTopicQueries = [
      'Bagaimana cara membuat tabel kebenaran untuk logika implikasi dan biimplikasi?',
      'Tolong jelaskan apa itu ingkaran atau negasi dari suatu pernyataan matematika',
      'Bagaimana menentukan nilai kebenaran dari konjungsi dan disjungsi?',
      'Bagaimana cara menghitung determinan matriks ordo 2x2 dan ordo 3x3?',
      'Bagaimana rumus mencari invers matriks persegi berordo 2x2?',
      'Bagaimana cara menyelesaikan sistem persamaan linier dua variabel dengan metode eliminasi?',
      'Apa pengertian variabel, koefisien, dan konstanta pada persamaan aljabar?',
      'Bagaimana cara menentukan daerah hasil atau range dari suatu fungsi linear?',
      'Bagaimana cara mencari nilai limit fungsi aljabar x mendekati tak hingga?',
      'Bagaimana konsep turunan pertama fungsi dan aplikasinya dalam mencari gradien garis singgung?',
    ];

    // 10 Kueri Out-of-Topic (Game, Hiburan, Cuaca, Curhat Umum)
    final outOfTopicQueries = [
      'Rekomendasi build item hero Mobile Legends paling sakit untuk push rank', // Game
      'Tips setting sensitivitas senjata di game Valorant agar selalu headshot', // Game
      'Kapan jadwal tayang film anime terbaru di bioskop CGV minggu ini?', // Hiburan
      'Rekomendasi playlist lagu pop galau Indonesia yang enak didengar', // Hiburan
      'Apakah besok pagi di Jakarta akan turun hujan lebat atau cuaca cerah?', // Cuaca
      'Prakiraan cuaca untuk wilayah Bandung hari ini berawan atau panas?', // Cuaca
      'Aku lagi sedih dan galau banget kak habis putus cinta sama pacar', // Curhat umum
      'Resep rahasia membuat nasi goreng seafood spesial yang gurih dan lezat', // Kuliner
      'Badanku lemas banget hari ini malas ngapa-ngapain rasanya mau tidur seharian', // Curhat umum
      'Berapa harga tiket pesawat promo dari Jakarta ke Bali untuk liburan akhir tahun?', // Umum
    ];

    setUp(() {
      filterService = TfidfFilterService();
    });

    test('Evaluasi Akurasi pada Threshold 0.2, 0.3, 0.4, dan 0.5', () {
      final thresholds = [0.2, 0.3, 0.4, 0.5];

      // ignore: avoid_print
      print('\n================================================================================');
      // ignore: avoid_print
      print('          HASIL EVALUASI AKURASI TF-IDF FILTER SERVICE (BAB III PROPOSAL)       ');
      // ignore: avoid_print
      print('================================================================================');

      // Tampilkan skor individual tiap query
      // ignore: avoid_print
      print('\n--- [DAFTAR KUERI & SKOR COSINE SIMILARITY] ---');
      // ignore: avoid_print
      print('1. Kueri In-Topic (Target: Relevan / Matematika SMK):');
      for (var i = 0; i < inTopicQueries.length; i++) {
        final q = inTopicQueries[i];
        final res = filterService.validateQuery(q, threshold: 0.0);
        // ignore: avoid_print
        print('   [#${(i + 1).toString().padLeft(2)}] Skor: ${res.score.toStringAsFixed(4)} | "$q"');
      }

      // ignore: avoid_print
      print('\n2. Kueri Out-of-Topic (Target: Tidak Relevan / Game, Cuaca, Hiburan, Curhat):');
      for (var i = 0; i < outOfTopicQueries.length; i++) {
        final q = outOfTopicQueries[i];
        final res = filterService.validateQuery(q, threshold: 0.0);
        // ignore: avoid_print
        print('   [#${(i + 1).toString().padLeft(2)}] Skor: ${res.score.toStringAsFixed(4)} | "$q"');
      }

      // ignore: avoid_print
      print('\n================================================================================');
      // ignore: avoid_print
      print('| Threshold |   TP  |   FN  |   TN  |   FP  | Total Kueri |    Akurasi (%)   |');
      // ignore: avoid_print
      print('--------------------------------------------------------------------------------');

      final resultsMap = <double, Map<String, dynamic>>{};

      for (final th in thresholds) {
        var tp = 0; // In-topic lolos
        var fn = 0; // In-topic terblokir
        var tn = 0; // Out-of-topic terblokir
        var fp = 0; // Out-of-topic lolos

        // Evaluasi In-Topic
        for (final query in inTopicQueries) {
          final res = filterService.validateQuery(query, threshold: th);
          if (res.isRelevant) {
            tp++;
          } else {
            fn++;
          }
        }

        // Evaluasi Out-of-Topic
        for (final query in outOfTopicQueries) {
          final res = filterService.validateQuery(query, threshold: th);
          if (res.isRelevant) {
            fp++;
          } else {
            tn++;
          }
        }

        final total = tp + fn + tn + fp;
        final accuracy = (tp + tn) / total * 100.0;

        resultsMap[th] = {
          'tp': tp,
          'fn': fn,
          'tn': tn,
          'fp': fp,
          'total': total,
          'accuracy': accuracy,
        };

        // Format cetak baris tabel
        final thStr = th.toStringAsFixed(1).padLeft(9);
        final tpStr = tp.toString().padLeft(5);
        final fnStr = fn.toString().padLeft(5);
        final tnStr = tn.toString().padLeft(5);
        final fpStr = fp.toString().padLeft(5);
        final totalStr = total.toString().padLeft(11);
        final accStr = '${accuracy.toStringAsFixed(1)}%'.padLeft(16);

        // ignore: avoid_print
        print('|$thStr |$tpStr |$fnStr |$tnStr |$fpStr |$totalStr |$accStr |');
      }

      // ignore: avoid_print
      print('================================================================================\n');

      // Verifikasi hasil evaluasi:
      // Total kueri selalu 20 untuk setiap threshold
      for (final th in thresholds) {
        expect(resultsMap[th]!['total'], equals(20));
      }

      // Pada threshold default 0.3:
      // Akurasi harus optimal (100%), TP = 10, FN = 0, TN = 10, FP = 0
      final res03 = resultsMap[0.3]!;
      expect(res03['tp'], equals(10), reason: 'Seluruh in-topic harus lolos pada threshold 0.3');
      expect(res03['fn'], equals(0), reason: 'Tidak boleh ada in-topic yang terblokir pada threshold 0.3');
      expect(res03['tn'], equals(10), reason: 'Seluruh out-of-topic harus terblokir pada threshold 0.3');
      expect(res03['fp'], equals(0), reason: 'Tidak boleh ada out-of-topic yang lolos pada threshold 0.3');
      expect(res03['accuracy'], equals(100.0), reason: 'Akurasi threshold 0.3 harus 100.0%');

      // Pada threshold 0.2: ada kata umum (misal 'atau') yang meloloskan kueri luar topik (FP > 0)
      final res02 = resultsMap[0.2]!;
      expect(res02['fp'], greaterThan(0), reason: 'Threshold 0.2 terlalu rendah sehingga menghasilkan FP');

      // Pada threshold 0.5: mulai terjadi pemblokiran terhadap pertanyaan relevan yang skornya < 0.5 (FN > 0)
      final res05 = resultsMap[0.5]!;
      expect(res05['fn'], greaterThan(0), reason: 'Threshold 0.5 terlalu ketat sehingga menghasilkan FN');
    });
  });
}
